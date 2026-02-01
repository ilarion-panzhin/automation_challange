# Terraform – Infrastructure Guide

This folder contains Terraform code that provisions the baseline Azure infrastructure for the project:
- Log Analytics Workspace (Azure Monitor / Container Insights)
- Two AKS clusters (primary + secondary region) for a simple multi-region setup (MVP)

---

## Repository structure

```
infra/terraform/
  versions.tf      # Terraform + provider version pinning
  providers.tf     # AzureRM provider configuration
  main.tf          # Data source: existing Resource Group lookup
  variables.tf     # Input variables (naming, regions, node sizes, tags)
  loganalytics.tf  # Log Analytics Workspace used by AKS monitoring
  aks.tf           # Primary AKS cluster
  aks_b.tf         # Secondary AKS cluster (Region B)
  outputs.tf       # Outputs for scripting/CI usage
```

---

## Prerequisites

- Terraform CLI >= 1.6.0
- Azure access (local dev: `az login`; CI: Service Principal or Managed Identity)
- Correct subscription selected / permissions granted

Recommended Azure CLI check:
```bash
az account show
az account set --subscription <subscription-id>
```

---

## Quick start (local)

### 1) Format
Formats all `.tf` files to a consistent style:
```bash
terraform fmt -recursive
```

### 2) Init
Downloads providers and initializes the working directory:
```bash
terraform init
```

### 3) Validate
Static configuration validation:
```bash
terraform validate
```

### 4) Plan
Shows what will change (no resources are modified):
```bash
terraform plan
```

### 5) Apply
Applies the planned changes:
```bash
terraform apply
```

Recommended safer flow:
```bash
terraform plan -out=tfplan
terraform apply tfplan
```

---

## What Terraform creates

### Resource Group
Terraform does NOT create the Resource Group in this project.
It reads an existing RG via a data source:
- `data.azurerm_resource_group.rg`

### Log Analytics Workspace
- `azurerm_log_analytics_workspace.law`

Used by AKS `oms_agent` (Container Insights).

### AKS clusters
- `azurerm_kubernetes_cluster.aks` (primary)
- `azurerm_kubernetes_cluster.aks_b` (secondary region)

Both clusters are configured with:
- System-assigned Managed Identity
- Default node pool
- Azure CNI networking
- Monitoring via Log Analytics (oms_agent)

---

## Important decisions

### VM size: `Standard_D2s_v5`
Default node size is configured via `var.node_vm_size`.

Why:
- Good general-purpose default for MVP/dev environments
- Typically 2 vCPU / 8 GiB RAM
- "s" = Premium SSD capable, "v5" = generation

Trade-offs:
- Small clusters may become CPU-limited quickly when running ingress + monitoring + multiple apps.
- For heavier workloads consider D4s_v5 (more CPU) or E-series (more memory).

### Monitoring via `oms_agent`
We explicitly enable AKS monitoring by linking AKS to the Log Analytics Workspace:
- Enables Container Insights
- Central place for logs and metrics

### Lifecycle ignore_changes on upgrade settings (primary cluster)
In `aks.tf` we ignore changes for `default_node_pool[0].upgrade_settings` to avoid noisy diffs.
AKS/Azure may adjust upgrade settings automatically and Terraform would otherwise show perpetual drift.

---

## CI/CD recommended flow

### PR pipeline (validation + preview)
Goal: validate code quality and generate a plan for review.

Suggested steps:
1. `terraform fmt -check -recursive`
2. `terraform init`
3. `terraform validate`
4. `terraform plan` (publish plan output to PR)

Optional:
- `tflint`, `tfsec` / `checkov` (security scanning)
- policy-as-code gate (deny public exposure, require tags, etc.)

### Main branch pipeline (deploy)
Goal: apply changes in a controlled, auditable way.

Suggested steps:
1. `terraform init`
2. `terraform plan -out=tfplan` (store artifact)
3. Manual approval gate (stage/prod)
4. `terraform apply tfplan`
5. Post-deploy checks (smoke tests, monitoring checks)

---

## Next improvements (recommended)

### 1) Remote state + locking (Azure Storage backend)
Currently, Terraform state may be stored locally.
For team/CI usage we should move to remote backend to enable:
- shared state
- state locking
- better auditability

Typical backend choice:
- Azure Storage Account + container + blob key

### 2) Secrets hygiene
Avoid placing secrets into Terraform state.
Use:
- Azure Key Vault for secrets
- data sources to reference existing secrets where possible

### 3) Environment separation
For dev/stage/prod:
- separate backend state keys per env
- separate tfvars per env (or separate folders)
- same codebase, different inputs

### 4) Least privilege for CI identity
CI identity (Service Principal / Managed Identity) should have only required permissions:
- Contributor only where needed, scoped to resource group(s)
- Avoid broad subscription-wide permissions if possible

---

## Troubleshooting

### "Plan shows changes every time"
Most common reasons:
- Azure-managed fields drift (some AKS settings are adjusted by Azure)
- Provider version changed
- Manual changes made in Azure Portal

Suggested actions:
- Check what fields drift (`terraform plan` output)
- Pin provider versions (already done)
- Use `lifecycle.ignore_changes` only for known noisy fields

### "Resource already exists"
This project reads an existing Resource Group. If other resources already exist:
- import them into state (`terraform import`) OR
- rename resources / change prefix

---

## Useful outputs
After apply, Terraform prints:
- `rg_name`, `rg_location`
- `aks_name`, `aks_b_name`

These can be used in scripts, e.g.:
```bash
az aks get-credentials -g <rg_name> -n <aks_name>
```

---