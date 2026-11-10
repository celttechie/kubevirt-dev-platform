# ADR 0001: Dedicated Nested Virtualization Sandbox on Bare-Metal NVMe

## Status
Accepted

## Context
Developing and validating upstream contributions to cloud-native virtualization projects (such as CNCF KubeVirt, Containerized Data Importer (CDI), and `virtctl`) requires access to real hardware virtualization acceleration (`/dev/kvm`). In software emulation mode (`useEmulation: true`), virtual machines crawl at a fraction of native speed, virtio devices lack hardware offloads, live migration behaves unrealistically, and nested QEMU processes incur high CPU penalties.

Additionally, bare-metal hypervisor nodes frequently host other co-located operational services or existing isolated application sandboxes. Running virtual machine disk test suites—including importing raw/QCOW2 disk images, Windows ISO slipstreaming with `virtio-win`, and CDI scratch space staging—imposes heavy I/O throughput and storage capacity requirements that risk disk-pressure evictions or resource contention if co-located on a shared general-purpose root filesystem.

## Decision
We decided to provision a **dedicated nested hypervisor guest** (`kubevirt-sandbox-vm`) on the bare-metal KVM host via OpenTofu and Libvirt, configured as follows:
1. **Compute Resources:** 8 vCPUs with CPU mode set to `host-passthrough`, directly exposing hardware virtualization flags (Intel VT-x / AMD-V) into the guest kernel.
2. **Memory:** 32 GB RAM dedicated to the guest domain to provide ample buffer for multi-VM orchestration and control plane components.
3. **Storage:** 120 GB QCOW2 sparse root disk backed by a high-speed bare-metal NVMe storage pool.
4. **Hardware KVM Enforcement:** `developerConfiguration.useEmulation = false` is strictly enforced in `manifests/kubevirt-cr.yaml`, failing fast if `/dev/kvm` is absent or unaccelerated.

## Consequences

### Positive
- **Hardware Acceleration:** Native KVM performance enables sub-second boot times for containerdisks (e.g., CirrOS boots to `Running` in <12s) and realistic live migration benchmarks.
- **Strict Isolation:** Heavy I/O from CDI DataVolume uploads, bulk image conversions, or corrupted guest kernels cannot impact host workloads or neighboring virtual environments.
- **Storage Headroom:** 120 GB on fast NVMe storage provides ample space for multiple guest operating systems (Linux, Windows), local containerd image caches, and scratch PVCs.

### Negative
- **Resource Reservation:** 32 GB of host memory is committed to the sandbox domain while running.
- **Nested Virtualization Layer:** While hardware-accelerated, nested virtualization incurs minor hypervisor overhead compared to running directly on bare metal.
