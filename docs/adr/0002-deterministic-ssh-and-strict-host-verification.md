# ADR 0002: Deterministic SSH Key Architecture and Strict Host Verification

## Status
Accepted

## Context
Many developer sandboxes, ephemeral lab VMs, and automation frameworks disable SSH host key verification by injecting `-o StrictHostKeyChecking=no` and `-o UserKnownHostsFile=/dev/null`. While convenient for throwaway environments, this practice introduces critical issues:
1. **Security Vulnerability:** Bypassing host key checking trains developers and automation pipelines to ignore man-in-the-middle (MITM) warnings and violates DoD IL4/IL5 security policies (e.g., NIST 800-53 IA-3, SC-8).
2. **Interactive Prompts in CI:** Unseeded `known_hosts` entries trigger terminal prompts that break non-interactive automation and background CI scripts.
3. **Ghost Host Key Warnings:** If an ephemeral VM is rebuilt with a new random host key on the same IP, subsequent SSH attempts crash with severe `REMOTE HOST IDENTIFICATION HAS CHANGED` warnings.

## Decision
We established a **deterministic cryptographic SSH model** across the platform:
1. **Pre-Generated Keypairs:**
   - Client ED25519 keypair is maintained at `substrate/keys/id_kubevirt_dev_ed25519`.
   - VM Host ED25519 keypair is maintained at `substrate/keys/ssh_host_ed25519_key`.
   - `scripts/keygen.sh` deterministically creates both keypairs on first run and is completely idempotent.
2. **Cloud-Init Injection:**
   - The host private and public keys are baked into the VM seed ISO (`cloudinit.iso`).
   - Cloud-init is configured with `ssh_deletekeys: true`, ensuring any default host keys in the base Ubuntu cloud image are erased and replaced by our deterministic host key.
   - Files are also written explicitly to `/etc/ssh/ssh_host_ed25519_key` (permissions `0600`) and `.pub` (permissions `0644`).
   - The client public key is injected into the administrative user's `~/.ssh/authorized_keys`.
3. **Pre-Seeded Known Hosts:**
   - `scripts/keygen.sh` writes the matching public key hash into `.ssh/known_hosts` for both the configured VM IP and hostname.
4. **Strict Enforcement:**
   - `.ssh/config` enforces `StrictHostKeyChecking yes` and `CheckHostIP yes`.
   - Private keys are strictly excluded from git tracking via `.gitignore`.

## Consequences

### Positive
- **Zero-Bypass Security:** Full compliance with DoD IL5 and enterprise zero-trust standards; no security flags are disabled.
- **Reliable Automation:** `make ssh`, `make install-virt`, and `make test-e2e` connect instantly without prompts, warnings, or MITM errors.
- **Rebuild Immunity:** Destroying and rebuilding the VM (`make destroy && make apply`) reproduces the exact same host key, meaning local `known_hosts` never becomes stale or corrupted.

### Negative
- **Key Storage Hygiene:** Private keys in `substrate/keys/` and `.ssh/` must remain local and uncommitted to public source control (guarded by `.gitleaks.toml` and `.gitignore`).
