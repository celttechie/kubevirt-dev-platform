.PHONY: all keygen plan apply destroy install-virt snapshot-pristine restore-pristine snapshot-list test-e2e test-static ssh clean

SHELL := /usr/bin/env bash

all: test-static

keygen:
	@echo "==> Generating deterministic SSH keys..."
	@./scripts/keygen.sh

init: keygen
	@echo "==> Initializing OpenTofu substrate..."
	@cd substrate && tofu init

plan: keygen
	@echo "==> Running OpenTofu plan..."
	@cd substrate && tofu plan

apply: keygen
	@echo "==> Applying OpenTofu substrate..."
	@cd substrate && tofu apply -auto-approve

destroy:
	@echo "==> Destroying OpenTofu substrate..."
	@cd substrate && tofu destroy -auto-approve

ssh: keygen
	@echo "==> Connecting to kubevirt-sandbox (strict host verification)..."
	@ssh -F .ssh/config kubevirt-sandbox

install-virt: keygen
	@echo "==> Deploying Kubernetes & KubeVirt stack..."
	@./scripts/install_k8s_virt.sh

snapshot-pristine:
	@echo "==> Creating pristine baseline snapshot..."
	@./scripts/snapshot_manager.sh create pristine-baseline

restore-pristine:
	@echo "==> Reverting to pristine baseline snapshot..."
	@./scripts/snapshot_manager.sh revert pristine-baseline

snapshot-list:
	@echo "==> Listing available domain snapshots..."
	@./scripts/snapshot_manager.sh list

test-e2e:
	@echo "==> Running end-to-end KubeVirt verification..."
	@./tests/e2e_test.sh

test-static: keygen
	@echo "==> Running static linting, schema validation & security checks..."
	@shellcheck scripts/*.sh tests/*.sh
	@cd substrate && tofu fmt -check && tofu validate
	@python3 -c 'import pathlib, yaml; [list(yaml.safe_load_all(f.read_text())) for p in ["manifests/**/*.yaml", "zarf/**/*.yaml", "tests/**/*.yaml"] for f in sorted(pathlib.Path(".").glob(p))]; print("YAML manifests & templates valid!")'
	@echo "==> All static verification gates passed!"

clean:
	@echo "==> Cleaning transient build and state files..."
	@rm -rf kubeconfig /tmp/test_vmi.yaml
