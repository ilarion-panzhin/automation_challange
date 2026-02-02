terraform {
  # Enforces the minimum Terraform CLI version required for this configuration.
  # Practical: avoids running with older Terraform versions that may behave differently or fail.
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      # Defines which provider to download: Azure Resource Manager provider from HashiCorp.
      # Practical: Terraform uses this to know where to fetch the plugin from.
      source = "hashicorp/azurerm"

      # Pins the provider version range.
      # "~> 4.0" means: allow any 4.x version, but do NOT upgrade to 5.0 automatically.
      # Practical: keeps builds stable while still allowing safe minor/patch updates within v4.
      version = "~> 4.0"
    }
  }
}
