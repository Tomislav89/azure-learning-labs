resource "azurerm_resource_group" "app_dev" {
  name     = "rg-app-dev"
  location = "West Europe"

  tags = {
    Environment = "DEV"
    Project     = "AzureLearning"
    CostCenter  = "LAB"
    ManagedBy   = "Terraform"
  }
}
