## 📌 Summary of Changes
<!-- Provide a clear and concise summary of the changes introduced by this pull request. -->

---

## 🏷️ Type of Change
- [ ] 🚀 `feat`: New virtualization feature or capability (KubeVirt / CDI / UDS)
- [ ] 🐛 `fix`: Bug fix
- [ ] 📝 `docs`: Documentation updates or ADRs
- [ ] ♻️ `refactor`: Refactoring without behavior change
- [ ] 🧪 `test`: Unit / e2e integration test additions
- [ ] 🔧 `chore`: Substrate, OpenTofu, dependencies, CI/CD

---

## 📑 Upstream / Defense Unicorns Objectives
<!-- Reference relevant upstream KubeVirt issues/VEPs or Defense Unicorns UDS VM goals. -->
- **Upstream CNCF Issue / VEP:** 
- **UDS VM / Disconnected Delivery Impact:** 

---

## 🧪 Verification & Testing Gates
<!-- Detail the verification steps performed and evidence of passing status. -->

### 1. Static Checks & Shift-Left Gates
```bash
make test-static
```

### 2. Live Substrate & Cluster Verification
```bash
# Example: make test-e2e
```

### 3. Snapshot & Recovery Verification
- [ ] Verified that snapshot creation (`make snapshot-pristine`) and restore (`make restore-pristine`) succeeds cleanly without state corruption.

---

## 🛡️ Security & DoD IL4/IL5 Compliance Checklist
- [ ] **Deterministic SSH:** All host keys and client keys are deterministically provisioned; strict host key checking (`StrictHostKeyChecking=yes`) passes.
- [ ] **No Secret Leaks:** No unencrypted credentials, tokens, or private keys committed (verified by Gitleaks).
- [ ] **Non-Root / Isolation:** Workloads adhere to Kubernetes Pod Security Standards and KubeVirt isolation requirements.
- [ ] **Air-Gap Capable:** No unexpected runtime WAN egress during disconnected operations.
