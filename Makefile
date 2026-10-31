.PHONY: all infra configure platform test destroy

TF_DIR := terraform/proxmox
export KUBECONFIG := $(CURDIR)/kubeconfig

all: infra configure platform test

infra:
	terraform -chdir=$(TF_DIR) init -input=false
	terraform -chdir=$(TF_DIR) apply -auto-approve
	rm -f ~/.ssh/known_hosts_homelab

configure:
	cd ansible && ansible-galaxy collection install -r requirements.yml && ansible-playbook site.yml

platform:
	./scripts/bootstrap-platform.sh

test:
	./scripts/smoke-test.sh

destroy:
	terraform -chdir=$(TF_DIR) destroy -auto-approve
	rm -f kubeconfig ~/.ssh/known_hosts_homelab
