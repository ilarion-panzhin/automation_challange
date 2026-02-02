resource "azurerm_log_analytics_workspace" "law" {
  # Creates an Azure Log Analytics Workspace (used by Azure Monitor).
  # Practical: central place to store and query logs/metrics from AKS and other Azure resources.
  # In this project it is used by AKS via the oms_agent (Container Insights).
  name = "${var.prefix}-law"

  # Uses the same Azure region as the existing Resource Group.
  # Practical: keeps management resources close to the main infrastructure and avoids region mismatch surprises.
  location = data.azurerm_resource_group.rg.location

  # Deploys the workspace into an existing Resource Group (looked up via data source).
  resource_group_name = data.azurerm_resource_group.rg.name

  # Pricing tier for Log Analytics.
  # "PerGB2018" = pay per ingested GB.
  sku = "PerGB2018"

  # Data retention period in days for logs stored in the workspace.
  # Practical: controls how long you can query historical logs and impacts cost.
  retention_in_days = 30

  # Tags for governance and cost allocation.
  tags = var.tags
}
