resource "azurerm_kubernetes_cluster" "aks_b" {
  # Declares an AKS cluster resource managed by Terraform.
  # "aks_b" is Terraform’s internal name for referencing this cluster in other files.
  # Purpose: second cluster (B) for multi-region / higher availability design.
  name = "${var.prefix}-aks-b"

  # Azure region where this cluster will be deployed (e.g., northeurope).
  # Kept as a variable so you can switch regions per environment.
  location = var.location_b

  # Deploy into an existing Resource Group (looked up via data source).
  # Practical: RG is often pre-created by platform team / policies, and infra modules attach to it.
  resource_group_name = data.azurerm_resource_group.rg.name

  # DNS prefix used by AKS for its default internal DNS naming (cluster-related endpoints).
  # Not the same as your Ingress DNS; it’s AKS infrastructure naming.
  dns_prefix = "${var.prefix}-dns-b"

  # Apply consistent tags (cost, ownership, purpose) to the AKS resource.
  # Practical: makes governance, cost tracking, and searching easier.
  tags = var.tags

  identity {
    # Enables a system-assigned Managed Identity for the cluster.
    # Practical: AKS can authenticate to Azure services without storing credentials.
    type = "SystemAssigned"
  }

  default_node_pool {
    # The initial/system node pool (runs core system pods, and can run workloads too).
    # In more advanced setups you may add additional user node pools.
    name = "system"

    # VM SKU for the nodes. Kept as a variable to tune cost/performance per environment.
    vm_size = var.node_vm_size

    # Fixed number of nodes. For production you often use cluster autoscaler instead.
    node_count = var.node_count

    # Uses VM Scale Sets for the node pool (standard/modern AKS implementation).
    # Practical: supports scaling and upgrades cleanly.
    type = "VirtualMachineScaleSets"
  }

  # Observability: enable the AKS monitoring addon (Container Insights) and send data to Log Analytics.
  # Note: reusing the same workspace across regions is acceptable for an MVP; production may require per-region
  # workspaces for data residency/latency/segmentation.
  oms_agent {
    # Links AKS monitoring to the specific Log Analytics Workspace created in loganalytics.tf.
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  }

  network_profile {
    # Use Azure CNI networking.
    # Practical: better integration with Azure networking (pods get IPs from the VNet in Azure CNI modes),
    # but may require more IP planning than kubenet.
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
