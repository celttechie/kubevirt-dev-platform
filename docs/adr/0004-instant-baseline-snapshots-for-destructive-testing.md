# ADR 0004: Instant Pristine Baseline Snapshots for Destructive Testing

## Status
Accepted

## Context
Virtualization and storage development inherently involves high-risk, state-mutating operations:
- Testing custom storage provisioners, CSI block drivers, and raw volume attachments.
- Injecting faulty CDI DataVolume specs, corrupted QCOW2 headers, or invalid storage classes.
- Modifying KubeVirt control plane components (`virt-operator`, `virt-handler`, `virt-api`) and testing migration failure modes.
- Testing dirty cluster states, network partition drills, and node reboot recovery.

Rebuilding a Kubernetes virtualization cluster from scratch via IaC (`tofu destroy && tofu apply && install-virt`) takes 3 to 5 minutes. Repeating this cycle dozens of times during deep debugging creates significant friction in the developer inner loop.

## Decision
We implemented an **instant snapshot and restore harness** backed by Libvirt atomic snapshots:
1. **Pristine Baseline Snapshot:**
   - Once the cluster reaches a healthy steady state (K3s, KubeVirt Operator, CDI Operator, and storage classes all ready), `make snapshot-pristine` executes an atomic live snapshot named `pristine-baseline`.
   - The script flushes and quiesces guest filesystems via the installed `qemu-guest-agent` (`virsh snapshot-create-as --atomic --quiesce`).
2. **Instant Revert:**
   - When a test corrupts storage, breaks a controller, or leaves orphaned pods/PVCs, `make restore-pristine` executes `virsh snapshot-revert --domain kubevirt-sandbox-vm --snapshotname pristine-baseline --running`.
   - Reversion resets both disk delta blocks and guest memory state in **under 15 seconds**, resuming execution directly at the clean, initialized baseline.

## Consequences

### Positive
- **Sub-15s Rollback:** Reduces the reset cycle from ~5 minutes to ~12 seconds.
- **Destructive Testing Freedom:** Developers can experiment aggressively with custom builds and destructive failure modes without fear of time-consuming rebuilds.
- **Predictable Benchmark Baseline:** Guarantees that every benchmark or verification run begins with identical storage and memory conditions.

### Negative
- **Snapshot Disk Growth:** Running a domain off an active snapshot accumulates a QCOW2 copy-on-write delta file until committed or rebuilt.
- **Clock Sync on Revert:** Guest system clocks may briefly jump upon memory restore; the guest NTP/chrony daemon re-synchronizes within seconds.
