terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstatezivkovic26"
    container_name       = "tfstate"
    key                  = "test.tfstate"
    use_azuread_auth     = true
  }
}
