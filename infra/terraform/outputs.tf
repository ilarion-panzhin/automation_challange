output "rg_name" {
  # Exposes the Resource Group name as a Terraform output.
  # Practical: makes it easy for team/CI scripts to reference the RG after `apply`
  # (e.g., printing it in logs or passing it to Azure CLI steps).
  value = data.azurerm_resource_group.rg.name
}

output "rg_location" {
  # Exposes the Resource Group location (Azure region) as an output.
  # Practical: useful for debugging and for downstream steps that need region info.
  value = data.azurerm_resource_group.rg.location
}

output "aks_name" {
  # Exposes the primary AKS cluster name.
  # Practical: CI can use this output to fetch kubeconfig, e.g. `az aks get-credentials`.
  value = azurerm_kubernetes_cluster.aks.name
}

output "aks_b_name" {
  # Exposes the secondary AKS cluster name (cluster B in the second region).
  # Practical: same use case for automation / kubeconfig / deployment steps.
  value = azurerm_kubernetes_cluster.aks_b.name
}
