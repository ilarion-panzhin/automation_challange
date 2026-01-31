output "rg_name" {
  value = data.azurerm_resource_group.rg.name
}

output "rg_location" {
  value = data.azurerm_resource_group.rg.location
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}
