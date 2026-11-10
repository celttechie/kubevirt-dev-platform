# CNCF Virtualization Upstream Contribution Plan

This document outlines the roadmap and technical inner loops for contributing high-impact enhancements to **CNCF KubeVirt** and **Containerized Data Importer (CDI)**, specifically focused on virtualization in disconnected and air-gapped environments.

---

## 1. Upstream Alignment & Target Areas

The contribution targets directly align with key architectural challenges in cloud-native virtualization:

| Project | Subsystem / Focus Area | Impact & Relevance |
| :--- | :--- | :--- |
| **`kubevirt/kubevirt`** | **`virtctl` CLI Tools & Diagnostics** | Improve VM operator ergonomics, direct image upload streaming, pre-flight checks for hardware KVM, and air-gapped diagnostics. |
| **`kubevirt/containerized-data-importer`** | **Direct OCI Layer Extraction** | Optimize how CDI pulls and extracts VM disk layers directly from OCI registries without redundant intermediate scratch storage. |
| **`kubevirt/containerized-data-importer`** | **Disconnected & Proxy Registry Auth** | Enhance private registry authentication handling (custom TLS bundles, client certificate auth, image pull secrets) during air-gapped `DataVolume` imports. |
| **`kubevirt/containerized-data-importer`** | **Format Conversion Performance** | Optimize streaming conversions from `qcow2` / raw to block PVCs, minimizing temporary scratch disk allocation. |

---

## 2. Developer Inner Loop on the Platform

### Track A: Developing & Validating Custom `virtctl` Builds

`virtctl` is the official client binary for interacting with KubeVirt resources (console access, image uploads, live migration, VM control).

1. **Clone and Build Upstream `kubevirt/kubevirt`:**
   ```bash
   git clone https://github.com/kubevirt/kubevirt.git ~/workspace/upstream-kubevirt
   cd ~/workspace/upstream-kubevirt
   make virtctl
   ```
   *The compiled binary is output to `_out/cmd/virtctl/virtctl`.*

2. **Test Directly Against the `kubevirt-dev-platform` Cluster:**
   ```bash
   export KUBECONFIG=./kubeconfig

   # Test custom virtctl commands against the live cluster
   ./_out/cmd/virtctl/virtctl version
   ./_out/cmd/virtctl/virtctl image-upload dv test-dv --size=1Gi --image-path=/tmp/test.qcow2
   ```

3. **Validate Console & Port-Forwarding:**
   ```bash
   ./_out/cmd/virtctl/virtctl console cirros-test
   ./_out/cmd/virtctl/virtctl port-forward vmi/cirros-test 2222:22
   ```

4. **Instant Rollback on Failure:**
   ```bash
   # In kubevirt-dev-platform directory:
   make restore-pristine
   ```

---

### Track B: Developing Custom CDI Importer Components

The CDI importer pod (`importer`) is responsible for fetching external disk images (HTTP, S3, OCI registry) and converting them onto target PVCs.

1. **Clone Upstream CDI:**
   ```bash
   git clone https://github.com/kubevirt/containerized-data-importer.git ~/workspace/upstream-cdi
   cd ~/workspace/upstream-cdi
   ```

2. **Build Custom Importer Image:**
   ```bash
   # Build the container image locally
   DOCKER_PREFIX=<local-registry-ip>:5000 make container-cdi-importer
   ```

3. **Deploy to Sandbox & Override via CDI CR:**
   In [`manifests/cdi-cr.yaml`](../manifests/cdi-cr.yaml):
   ```yaml
   apiVersion: cdi.kubevirt.io/v1beta1
   kind: CDI
   metadata:
     name: cdi
   spec:
     config:
       imagePullPolicy: Always
     customizeComponents:
       patches:
         - resourceType: Deployment
           resourceName: cdi-deployment
           patch: '[{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "<local-registry-ip>:5000/cdi-importer:dev"}]'
           type: json
   ```
   Apply and observe the controller/importer behaviors under test.

---

## 3. Contribution Workflow & Standards

1. **GitHub Issues & SIG Discussions:**
   - Review open issues labeled `help wanted` or `good first issue` in `kubevirt/kubevirt` and `kubevirt/containerized-data-importer`.
   - Participate in bi-weekly **SIG Storage** and **SIG Compute** community calls.
2. **Virtualization Enhancement Proposals (VEPs):**
   - Major API changes or architectural adjustments follow the VEP process in `kubevirt/enhancements`.
3. **Commit Quality & Licensing:**
   - All commits must include Developer Certificate of Origin (DCO) sign-off (`git commit -s`).
   - Conventional commit formatting (`feat:`, `fix:`, `docs:`) with linked issue references (`Fixes #1234`).
