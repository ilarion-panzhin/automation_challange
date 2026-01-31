resource "azurerm_kubernetes_cluster" "aks_b" {
  name                = "${var.prefix}-aks-b"
  location            = var.location_b
  resource_group_name = data.azurerm_resource_group.rg.name
  dns_prefix          = "${var.prefix}-dns-b"
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name       = "system"
    vm_size    = var.node_vm_size
    node_count = var.node_count
    type       = "VirtualMachineScaleSets"
  }

  # Same Log Analytics workspace like for region westeurope. Assumtion: for MVP ok.
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  }

  network_profile {
    network_plugin = "azure"
  }
}
