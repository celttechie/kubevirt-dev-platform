# ADR 0003: Substrate Network Routing and Air-Gapped Workload Delivery Model

## Status
Accepted

## Context
When designing a development and test platform for Defense Unicorns UDS VM and upstream CNCF KubeVirt, two conflicting network requirements exist:
1. **Outer Substrate Agility:** The underlying nested hypervisor needs to download upstream packages (K3s release binaries, KubeVirt/CDI operator CRDs, Helm charts, OS package security updates) without complex offline mirror staging during initial tool development.
2. **Inner Air-Gapped Validation:** The target workloads (virtual machines, CDI DataVolumes, Zarf packages) must validate strict disconnected capabilities, private registry authentication, and offline package delivery without depending on active WAN egress.

Initial experiments placed the outer VM directly on an isolated host network without default gateway routing or external DNS forwarding. While strictly disconnected at the hypervisor level, this prevented bootstrap scripts from downloading K3s, container images, or operator manifests during provisioning, requiring cumbersome multi-step sidecar payload transfers.

## Decision
We adopted a **two-tier network architecture**:
1. **Outer Substrate Tier (Development Runtime):**
   - Attached to Libvirt's routed virtual network with outbound NAT, allowing the nested sandbox OS to install upstream packages, fetch K3s updates, and download container base images.
   - Configured with a static IP and route between the developer workstation and the hypervisor host, allowing direct `kubectl` and `virtctl` access over the network without requiring fragile multi-hop port forwards.
2. **Inner Workload Tier (Air-Gapped & Disconnected Testing):**
   - Disconnected delivery testing is conducted inside Kubernetes using **Zarf and in-cluster OCI registries**.
   - Virtual machine disk images and containerdisks are packaged into `.tar.zst` bundles, pushed to an offline registry (`127.0.0.1:31999` or Zot), and imported via CDI without external WAN calls.
   - Network policies and masquerade interfaces isolate VM tenant networks from host networking.

## Consequences

### Positive
- **Streamlined Inner Loop:** Substrate setup and operator deployment complete in under 3 minutes (`make apply` -> `make install-virt`).
- **Direct Workstation Tooling:** Local `kubectl` and `virtctl` interact natively with the cluster API endpoint without intermediate port-forward proxies.
- **True Air-Gap Validation:** Workloads run against local OCI registries and offline Zarf bundles, accurately testing the disconnected scenarios targeted by Defense Unicorns UDS VM.

### Negative
- **Dual-Mode Discipline:** Developers must explicitly test air-gapped Zarf packages rather than relying solely on online public image pulls during final bundle verification.
