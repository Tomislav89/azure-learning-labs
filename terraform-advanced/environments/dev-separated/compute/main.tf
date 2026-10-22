data "azurerm_resource_group" "dev" {
  name = "rg-terraform-dev"
}

data "terraform_remote_state" "networking" {
  backend = "azurerm"

  config = {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstatezivkovic26"
    container_name       = "tfstate"
    key                  = "dev-networking.tfstate"
    use_azuread_auth     = true
  }
}

module "compute" {
  source = "../../../modules/compute"

  nic_name            = "nic-app-dev"
  location            = data.azurerm_resource_group.dev.location
  resource_group_name = data.azurerm_resource_group.dev.name
  subnet_id           = data.terraform_remote_state.networking.outputs.app_subnet_id
}
