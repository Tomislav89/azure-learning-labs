data "azurerm_resource_group" "lab" {
  name = "rg-github-oidc-lab"
}

resource "azurerm_storage_account" "lab" {
  name                     = "stgha26lab001"
  resource_group_name      = data.azurerm_resource_group.lab.name
  location                 = data.azurerm_resource_group.lab.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  tags = {
    environment = "lab"
    managed_by  = "terraform"
    project     = "github-actions"
    owner       = "devops-lab"
  }
}
