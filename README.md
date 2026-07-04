# openshift-install-azure

Ansible automation for an OpenShift IPI (installer-provisioned infrastructure) install
on Azure. Configuration lives in git as plain YAML; secrets are ansible-vault encrypted;
generated/secret runtime artifacts (`bin/`, `clusters/*/`) are gitignored.

## Prerequisites

- `ansible` / `ansible-playbook` (2.17+)
- An Azure Service Principal with Contributor rights on the target subscription
- An existing Azure public DNS zone for your base domain
- A pull secret (`~/pull-secret.json` by default — [console.redhat.com/openshift/install/pull-secret](https://console.redhat.com/openshift/install/pull-secret))
- An SSH public key to inject into cluster nodes

## One-time setup

1. Create a local vault password file (never committed — already gitignored):

   ```sh
   openssl rand -base64 32 > .vault_pass
   chmod 600 .vault_pass
   ```

2. Edit `inventory/group_vars/all/vars.yml` for your cluster name, region, base domain,
   base-domain resource group, and paths to your pull secret / SSH key.

3. Put your Azure Service Principal credentials into `inventory/group_vars/all/vault.yml`
   (`azure_subscription_id`, `azure_tenant_id`, `azure_client_id`, `azure_client_secret`),
   then encrypt it:

   ```sh
   ansible-vault encrypt inventory/group_vars/all/vault.yml
   ```

   `ansible.cfg` is already configured to use `.vault_pass` automatically, so
   `ansible-playbook` runs stay non-interactive.

## Usage

Everything runs via tags, so the expensive/billed step is always explicit and opt-in:

```sh
# Download the openshift-install and oc clients into ./bin
ansible-playbook playbooks/install-cluster.yml --tags tools

# Write Azure SP credentials (~/.azure/osServicePrincipal.json) and render install-config.yaml
ansible-playbook playbooks/install-cluster.yml --tags config

# Actually provision the cluster on Azure (~40 min, incurs real cost)
ansible-playbook playbooks/install-cluster.yml --tags provision
```

Cluster credentials land in `clusters/<cluster_name>/auth/` (`kubeconfig`,
`kubeadmin-password`) once `provision` completes. That directory is gitignored.

### Tearing down

```sh
ansible-playbook playbooks/destroy-cluster.yml
```

You'll be prompted to type the cluster name to confirm before anything is destroyed.

## Notes

- `install-config.yaml` is re-rendered from the template on every `config` run — the
  template in git is the source of truth, the rendered copy under `clusters/<name>/` is
  local install-time state consumed by the installer.
- If a `provision` run fails partway through, either fix the issue and re-run
  `--tags provision`, or `rm -rf clusters/<cluster_name>/*` and start over from `config`.
