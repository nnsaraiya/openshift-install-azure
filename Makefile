.DEFAULT_GOAL := help
ANSIBLE_PLAYBOOK := ansible-playbook
ANSIBLE_VAULT    := ansible-vault
VAULT_FILE       := inventory/group_vars/all/vault.yml

.PHONY: help encrypt-vault decrypt-vault edit-vault validate install destroy clean clean-all

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

encrypt-vault: ## Encrypt the vault file (first time setup)
	$(ANSIBLE_VAULT) encrypt $(VAULT_FILE)

decrypt-vault: ## Decrypt the vault file for editing
	$(ANSIBLE_VAULT) decrypt $(VAULT_FILE)

edit-vault: ## Open the vault file in your editor
	$(ANSIBLE_VAULT) edit $(VAULT_FILE)

validate: ## Validate Azure credentials, DNS zone, and install-config (no cluster created)
	$(ANSIBLE_PLAYBOOK) playbooks/install-cluster.yml --tags tools,config,validate

install: ## Install the cluster (downloads tools, renders config, provisions on Azure)
	$(ANSIBLE_PLAYBOOK) playbooks/install-cluster.yml --tags tools,config,provision

destroy: ## DESTROY the cluster and all Azure resources (irreversible!)
	$(ANSIBLE_PLAYBOOK) playbooks/destroy-cluster.yml

clean: ## Remove cluster workspace dir (keeps downloaded binaries)
	$(ANSIBLE_PLAYBOOK) playbooks/install-cluster.yml --tags clean

clean-all: ## Remove cluster workspace AND downloaded binaries
	$(ANSIBLE_PLAYBOOK) playbooks/install-cluster.yml --tags clean,clean-bins
