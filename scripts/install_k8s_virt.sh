#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

KUBEVIRT_VERSION="${KUBEVIRT_VERSION:-v1.3.1}"
CDI_VERSION="${CDI_VERSION:-v1.66.1}"
SSH_CONFIG="${REPO_ROOT}/.ssh/config"

# If running remotely from workstation, delegate over strict SSH
if [[ -f "${SSH_CONFIG}" ]] && [[ "${1:-}" != "--local" ]]; then
  echo "==> Deploying Kubernetes & Virtualization stack to kubevirt-sandbox..."
  
  # Copy manifests and install script to target
  scp -F "${SSH_CONFIG}" -r "${REPO_ROOT}/manifests" kubevirt-sandbox:/tmp/manifests
  scp -F "${SSH_CONFIG}" "${BASH_SOURCE[0]}" kubevirt-sandbox:/tmp/install_k8s_virt.sh

  # Execute installation on remote node
  ssh -F "${SSH_CONFIG}" kubevirt-sandbox "bash /tmp/install_k8s_virt.sh --local"
  
  # Discover cluster IP from terraform.tfvars or default
  TARGET_IP="192.168.122.50"
  if [[ -f "${REPO_ROOT}/substrate/terraform.tfvars" ]]; then
    DETECTED_IP="$(grep -E '^\s*vm_ip\s*=' "${REPO_ROOT}/substrate/terraform.tfvars" | sed -E 's/.*=\s*"([^"]+)".*/\1/' || true)"
    if [[ -n "${DETECTED_IP}" ]]; then
      TARGET_IP="${DETECTED_IP}"
    fi
  fi

  # Retrieve kubeconfig for local workstation access
  echo "==> Fetching cluster kubeconfig to ${REPO_ROOT}/kubeconfig..."
  ssh -F "${SSH_CONFIG}" kubevirt-sandbox "sudo cat /etc/rancher/k3s/k3s.yaml" | \
    sed "s/127.0.0.1/${TARGET_IP}/g" > "${REPO_ROOT}/kubeconfig"
  chmod 600 "${REPO_ROOT}/kubeconfig"
  echo "==> Local kubeconfig ready at ${REPO_ROOT}/kubeconfig"
  exit 0
fi

# ==========================================
# Local Execution (runs inside sandbox VM)
# ==========================================
export KUBECONFIG="${KUBECONFIG:-/etc/rancher/k3s/k3s.yaml}"

echo "==> [Node] Validating hardware virtualization (/dev/kvm)..."
if [[ ! -e /dev/kvm ]]; then
  echo "ERROR: /dev/kvm is missing. Hardware nested virtualization is required." >&2
  exit 1
fi
echo "==> [Node] Hardware virtualization verified: $(ls -l /dev/kvm)"

# 1. Install K3s if not present
if ! command -v k3s >/dev/null 2>&1; then
  echo "==> [Node] Installing K3s..."
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik --write-kubeconfig-mode=644" sh -
  # Wait for K3s node ready
  while ! kubectl get nodes | grep -q "Ready"; do
    echo "    Waiting for K3s node to reach Ready state..."
    sleep 3
  done
else
  echo "==> [Node] K3s is already installed."
fi

# 2. Deploy KubeVirt Operator & CR
echo "==> [Node] Installing KubeVirt Operator (${KUBEVIRT_VERSION})..."
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml"

echo "==> [Node] Applying KubeVirt Custom Resource..."
kubectl apply -f /tmp/manifests/kubevirt-cr.yaml

# 3. Deploy CDI Operator & CR
echo "==> [Node] Installing CDI Operator (${CDI_VERSION})..."
kubectl apply -f "https://github.com/kubevirt/containerized-data-importer/releases/download/${CDI_VERSION}/cdi-operator.yaml"

echo "==> [Node] Applying CDI Custom Resource..."
kubectl apply -f /tmp/manifests/cdi-cr.yaml

# 4. Install virtctl client binary
if ! command -v virtctl >/dev/null 2>&1; then
  echo "==> [Node] Installing virtctl CLI client (${KUBEVIRT_VERSION})..."
  curl -sSL -o /tmp/virtctl "https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/virtctl-${KUBEVIRT_VERSION}-linux-amd64"
  sudo install -m 0755 /tmp/virtctl /usr/local/bin/virtctl
  rm -f /tmp/virtctl
fi

# 5. Wait for operators and pods
echo "==> [Node] Waiting for KubeVirt and CDI operators and control plane..."
kubectl wait -n kubevirt --for=condition=Available deployment/virt-operator --timeout=180s || true
kubectl wait -n cdi --for=condition=Available deployment/cdi-operator --timeout=180s || true
echo "==> [Node] Waiting for KubeVirt and CDI subsystems to be fully deployed..."
kubectl wait -n kubevirt kv kubevirt --for=condition=Available --timeout=300s || true
kubectl wait -n cdi cdi cdi --for=condition=Available --timeout=300s || true

echo "==> [Node] Kubernetes & KubeVirt stack initialized successfully!"
kubectl get pods -A
