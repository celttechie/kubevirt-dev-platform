#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Discover LIBVIRT_URI from environment, local tfvars, or fallback
if [[ -z "${LIBVIRT_URI:-}" ]] && [[ -f "${REPO_ROOT}/substrate/terraform.tfvars" ]]; then
  DETECTED_URI="$(grep -E '^\s*libvirt_uri\s*=' "${REPO_ROOT}/substrate/terraform.tfvars" | sed -E 's/.*=\s*"([^"]+)".*/\1/' || true)"
  if [[ -n "${DETECTED_URI}" ]]; then
    LIBVIRT_URI="${DETECTED_URI}"
  fi
fi
LIBVIRT_URI="${LIBVIRT_URI:-qemu:///system}"
VM_NAME="${VM_NAME:-kubevirt-sandbox-vm}"
ACTION="${1:-list}"
SNAPSHOT_NAME="${2:-pristine-baseline}"

usage() {
  cat <<EOF
Usage: $0 [create|revert|list|delete] [snapshot-name]

Commands:
  create [name]   Create an atomic snapshot of ${VM_NAME} (default: pristine-baseline)
  revert [name]   Revert ${VM_NAME} to the specified snapshot and resume execution
  list            List all available snapshots for ${VM_NAME}
  delete [name]   Delete the specified snapshot
EOF
  exit 1
}

check_domain() {
  if ! virsh -c "${LIBVIRT_URI}" dominfo "${VM_NAME}" >/dev/null 2>&1; then
    echo "ERROR: Domain '${VM_NAME}' not found on ${LIBVIRT_URI}" >&2
    exit 1
  fi
}

case "${ACTION}" in
  create)
    check_domain
    echo "==> Creating atomic snapshot '${SNAPSHOT_NAME}' for ${VM_NAME}..."
    # Attempt quiesced snapshot first via QEMU guest agent, fallback to non-quiesce if agent is unready
    if virsh -c "${LIBVIRT_URI}" snapshot-create-as \
        --domain "${VM_NAME}" \
        --name "${SNAPSHOT_NAME}" \
        --description "Pristine KubeVirt dev baseline" \
        --atomic \
        --quiesce 2>/dev/null; then
      echo "==> Snapshot '${SNAPSHOT_NAME}' created successfully (quiesced via guest agent)."
    else
      echo "    Guest agent quiesce unavailable, falling back to standard atomic snapshot..."
      virsh -c "${LIBVIRT_URI}" snapshot-create-as \
        --domain "${VM_NAME}" \
        --name "${SNAPSHOT_NAME}" \
        --description "Pristine KubeVirt dev baseline" \
        --atomic
      echo "==> Snapshot '${SNAPSHOT_NAME}' created successfully."
    fi
    ;;

  revert)
    check_domain
    echo "==> Reverting ${VM_NAME} to snapshot '${SNAPSHOT_NAME}'..."
    virsh -c "${LIBVIRT_URI}" snapshot-revert \
      --domain "${VM_NAME}" \
      --snapshotname "${SNAPSHOT_NAME}" \
      --running
    echo "==> Revert complete! VM '${VM_NAME}' is active at baseline state."
    ;;

  list)
    check_domain
    echo "==> Available snapshots for ${VM_NAME}:"
    virsh -c "${LIBVIRT_URI}" snapshot-list --domain "${VM_NAME}"
    ;;

  delete)
    check_domain
    echo "==> Deleting snapshot '${SNAPSHOT_NAME}' from ${VM_NAME}..."
    virsh -c "${LIBVIRT_URI}" snapshot-delete \
      --domain "${VM_NAME}" \
      --snapshotname "${SNAPSHOT_NAME}"
    echo "==> Snapshot '${SNAPSHOT_NAME}' deleted."
    ;;

  *)
    usage
    ;;
esac
