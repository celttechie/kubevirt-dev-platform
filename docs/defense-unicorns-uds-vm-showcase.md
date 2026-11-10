# Defense Unicorns UDS VM Showcase

This document demonstrates how the architecture and tooling in this repository directly implement the technical competencies and mission requirements of the **Senior Software Engineer - Virtual Machines (RD222)** role at **Defense Unicorns**.

---

## 1. Role Mission & Platform Mapping

The Defense Unicorns **UDS VM** mission delivers secure, repeatable, and automated virtual machine management alongside containerized workloads in **disconnected, air-gapped national security environments**.

| Defense Unicorns Requirement | Implementation in `kubevirt-dev-platform` |
| :--- | :--- |
| **Kubernetes & KubeVirt Core Competency** | Automated deployment of KubeVirt v1.3.1 with strict hardware KVM acceleration (`useEmulation: false`), virtio storage/networking, and CDI v1.66.1. |
| **Air-Gapped / Disconnected Delivery** | Zarf package definition ([`zarf/zarf.yaml`](../zarf/zarf.yaml)) bundling container images, CRDs, and disk assets into single `.tar.zst` payloads with in-cluster registry distribution. |
| **UDS Platform Integration** | Declarative UDS bundle definition ([`zarf/uds-bundle.yaml`](../zarf/uds-bundle.yaml)) orchestrating virtualization capabilities as modular packages. |
| **Automated Compliance & ATO Validation** | Lula DoD IL5 OSCAL component ([`zarf/oscal-component.yaml`](../zarf/oscal-component.yaml)) automating shift-left validation of NIST 800-53 controls (AC-3, SC-7). |
| **Deterministic Security & Zero-Trust** | Complete elimination of insecure SSH bypasses (`StrictHostKeyChecking=no`); deterministic ED25519 host/client keypair provisioning via cloud-init. |
| **Rapid Iteration & Disaster Recovery** | Instant atomic snapshot engine ([`scripts/snapshot_manager.sh`](../scripts/snapshot_manager.sh)) restoring clean baseline states in <15 seconds. |

---

## 2. Artifact Overview

### A. Zarf Virtualization Package (`zarf/zarf.yaml`)
Defines the air-gapped distribution bundle:
- **`kubevirt-operator`**: Operator images and custom resource definitions.
- **`cdi-operator`**: Containerized Data Importer for offline disk migration.
- **`sample-workload`**: Bundled offline containerdisk (`quay.io/kubevirt/cirros-container-disk-demo:latest`) ready for air-gapped execution without external registry dependencies.

### B. UDS Virtualization Capability (`zarf/uds-bundle.yaml`)
Enables composition into the Unified Defense Stack (UDS Core):
- Defines the `uds-capability-kubevirt` bundle.
- Manages dependencies, ingress policies, and resource boundaries.

### C. Lula OSCAL DoD IL5 Component Definition (`zarf/oscal-component.yaml`)
Validates that running virtual machines adhere to federal compliance requirements:
- **Control AC-3 (Access Enforcement):** Verifies hypervisor isolation boundaries and non-root execution constraints.
- **Control SC-7 (Boundary Protection):** Verifies that virtual machine interfaces attach through managed Kubernetes pod network masquerades rather than arbitrary host bridge bypasses.

---

## 3. Demonstrating Impact

This repository serves as tangible, live-validated proof of:
1. Deep operational expertise with **bare-metal hypervisor architecture** (VT-x nested KVM, Libvirt, QEMU guest agent, NVMe storage pools).
2. Proficiency in **cloud-native virtualization APIs** (KubeVirt CRDs, CDI DataVolumes, Pod networks).
3. Mastery of **air-gapped software delivery toolchains** (Zarf, UDS, Lula OSCAL, Gitleaks).
