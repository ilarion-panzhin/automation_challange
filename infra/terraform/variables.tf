variable "prefix" {
  # Common naming prefix used to build resource names (AKS, Log Analytics, etc.).
  # Practical: keeps names consistent and makes it easy to deploy multiple environments
  # by changing only one value (e.g., "devops-challenge-dev", "devops-challenge-prod").
  type    = string
  default = "devops-challenge"
}

variable "location" {
  # Primary Azure region for resources that follow the Resource Group location.
  # Practical: makes region configurable per environment.
  type    = string
  default = "westeurope"
}

variable "location_b" {
  # Secondary Azure region for the second AKS cluster (multi-region / HA setup).
  # Practical: provides geographic redundancy and an option for failover.
  type    = string
  default = "northeurope"
}

variable "tags" {
  # Standard tags applied to resources for governance and cost allocation.
  # Practical: helps with chargeback, ownership, and filtering in the Azure Portal.
  type = map(string)
  default = {
    purpose = "devops-challenge"
    author  = "ilarion"
  }
}

variable "node_vm_size" {
  # Azure VM size (SKU) used for each AKS worker node.
  # Standard_D2s_v5 = general-purpose VM, typically 2 vCPU and 8 GiB RAM;
  # "s" means Premium SSD support, "v5" is the generation.
  type    = string
  default = "Standard_D2s_v5"
}

variable "node_count" {
  # Number of nodes in the default system node pool.
  # Practical: simple fixed-size cluster for MVP; production often uses autoscaling instead.
  type    = number
  default = 2
}
