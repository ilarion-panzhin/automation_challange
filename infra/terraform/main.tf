data "azurerm_resource_group" "rg" {
  # Data source: reads an existing Azure Resource Group.
  # Practical: the Resource Group is often created outside this Terraform module
  # (by a platform team, policies, or manually in a sandbox), and this code "attaches" to it.
  # Terraform will NOT create or modify the Resource Group here; it only fetches its properties.
  name = "rg-devops-challenge-ilar"
}
