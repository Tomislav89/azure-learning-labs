resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name_prefix}"
  location = "North Europe"
}

module "networking" {
  source = "../../../modules/networking"

  vnet_name           = "vnet-dev"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  subnets = {
    web = {
      address_prefix = "10.10.1.0/24"
      service        = "frontend"
    }

    app = {
      address_prefix = "10.10.2.0/24"
      service        = "application"
    }

    db = {
      address_prefix = "10.10.3.0/24"
      service        = "database"
    }

    management = {
      address_prefix = "10.10.4.0/24"
      service        = "management"
    }
  }
}

resource "azurerm_network_security_group" "app" {
  name                = "nsg-app-dev"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  dynamic "security_rule" {
    for_each = local.security_rules

    content {
      name                       = security_rule.key
      priority                   = security_rule.key == "http" ? 100 : 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = security_rule.value.port
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
}
