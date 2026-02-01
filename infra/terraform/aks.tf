resource "azurerm_kubernetes_cluster" "aks" {
  # Declares the primary AKS cluster managed by Terraform.
  # "aks" is Terraform’s internal name used for references (e.g., outputs, dependencies).
  name = "${var.prefix}-aks"

  # Places the cluster in the same region as the existing Resource Group.
  # Practical: avoids region mismatch errors and keeps "RG + AKS" co-located by default.
  location = data.azurerm_resource_group.rg.location

  # Deploy into an existing Resource Group (looked up via data source).
  # Practical: common when RG is created outside this module (platform baseline / policies).
  resource_group_name = data.azurerm_resource_group.rg.name

  # DNS prefix used for AKS-managed DNS names (AKS infrastructure endpoints).
  # Not your public application DNS (that comes later via Ingress/DNS).
  dns_prefix = "${var.prefix}-dns"

  # Standard tags for governance: ownership, cost allocation, purpose, etc.
  tags = var.tags

  identity {
    # Enables system-assigned Managed Identity for AKS.
    # Practical: avoids embedding credentials; AKS can access Azure resources via RBAC.
    type = "SystemAssigned"
  }

  default_node_pool {
    # The initial/system node pool, typically hosting core Kubernetes system components.
    name = "system"

    # Node VM SKU (cost/performance knob) provided via variables for easy environment tuning.
    vm_size = var.node_vm_size

    # Fixed number of nodes. In production you often enable autoscaling instead.
    node_count = var.node_count

    # VM Scale Sets is the standard node pool type in AKS (supports scaling/upgrades).
    type = "VirtualMachineScaleSets"
  }

  oms_agent {
    # Enables AKS monitoring addon (Container Insights) and ships logs/metrics to Log Analytics.
    # Practical: gives you cluster logs, container logs, and basic performance insights.
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  }

  network_profile {
    # Use Azure CNI for networking.
    # Practical: stronger Azure networking integration; requires IP planning in real environments.
    network_plugin = "azure"
  }

  lifecycle {
    # Prevents Terraform from constantly detecting drift on AKS-managed upgrade settings.
    # Practical: Azure/AKS may modify upgrade_settings automatically; ignoring avoids "noisy" plans.
    ignore_changes = [
      # Index [0] refers to the first (and here only) default_node_pool block.
      default_node_pool[0].upgrade_settings
    ]
  }
}
