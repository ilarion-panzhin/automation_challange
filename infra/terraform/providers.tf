provider "azurerm" {
  # Configures the AzureRM provider (Terraform plugin that talks to Azure Resource Manager APIs).
  # Practical: without this provider block, Terraform cannot create/read Azure resources.
  features {}
  # Required by the AzureRM provider. It enables provider-specific feature flags and defaults.
  # Most projects keep it empty unless they need to tweak specific behaviors.

  subscription_id = "2fc0173e-cada-4000-82db-566c79d396db"
  # Target Azure subscription where resources will be managed.
  #
  # Practical note:
  # - Hardcoding is OK for a sandbox challenge, but in real CI/CD it's usually injected via
  #   environment variables or pipeline variables (or derived from the authenticated identity),
  #   so the same Terraform code can deploy to dev/stage/prod subscriptions without code changes.
}
