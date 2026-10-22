terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstatezivkovic26"
    container_name       = "tfstate"
    key                  = "dev-networking.tfstate"
    use_azuread_auth     = true
  }
}
