resource "azurerm_virtual_network" "networking" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space

  tags = var.tags
}

resource "azurerm_subnet" "web" {
  name                 = var.web_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.networking.name
  address_prefixes     = [var.web_subnet_prefix]
}

resource "azurerm_subnet" "app" {
  name                 = var.app_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.networking.name
  address_prefixes     = [var.app_subnet_prefix]
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = var.private_endpoints_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.networking.name
  address_prefixes     = [var.private_endpoints_subnet_prefix]
}
