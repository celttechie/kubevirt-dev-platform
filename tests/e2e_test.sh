#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SSH_CONFIG="${REPO_ROOT}/.ssh/config"

echo "==> Running live KubeVirt E2E verification test..."

if [[ -f "${SSH_CONFIG}" ]] && [[ "${1:-}" != "--local" ]]; then
  # Copy test manifest and test script to target
  scp -F "${SSH_CONFIG}" "${SCRIPT_DIR}/test_vmi.yaml" kubevirt-sandbox:/tmp/test_vmi.yaml
  scp -F "${SSH_CONFIG}" "${BASH_SOURCE[0]}" kubevirt-sandbox:/tmp/e2e_test.sh
  # Execute test on remote node
  ssh -F "${SSH_CONFIG}" kubevirt-sandbox "bash /tmp/e2e_test.sh --local"
  exit 0
fi

# ==========================================
# Local Execution (runs inside sandbox VM)
# ==========================================
export KUBECONFIG="${KUBECONFIG:-/etc/rancher/k3s/k3s.yaml}"

echo "==> [Node] Applying Alpine test VMI..."
kubectl apply -f /tmp/test_vmi.yaml

echo "==> [Node] Waiting for VMI to reach Running phase (up to 120s)..."
for i in {1..40}; do
  PHASE="$(kubectl get vmi alpine-test -n default -o jsonpath='{.status.phase}' 2>/dev/null || echo 'Pending')"
  echo "    VMI Phase: ${PHASE} (attempt ${i}/40)"
  if [[ "${PHASE}" == "Running" ]]; then
    echo "==> [Node] Success: VMI alpine-test reached Running phase!"
    break
  fi
  sleep 3
done

if [[ "${PHASE}" != "Running" ]]; then
  echo "ERROR: VMI failed to reach Running phase within timeout." >&2
  kubectl describe vmi alpine-test -n default
  exit 1
fi

echo "==> [Node] Inspecting VMI runtime status..."
kubectl get vmi alpine-test -n default -o wide

echo "==> [Node] Cleaning up test VMI..."
kubectl delete -f /tmp/test_vmi.yaml --wait=true
echo "==> [Node] E2E verification completed successfully!"
