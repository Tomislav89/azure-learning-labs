resource "azurerm_virtual_network" "peer" {
  name                = var.peer_vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.peer_vnet_address_space

  tags = var.tags
}

resource "azurerm_subnet" "peer" {
  name                 = var.peer_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.peer.name
  address_prefixes     = [var.peer_subnet_prefix]
}

resource "azurerm_virtual_network_peering" "networking_to_peer" {
  name                      = "peer-networking-to-peer"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.networking.name
  remote_virtual_network_id = azurerm_virtual_network.peer.id
}

resource "azurerm_virtual_network_peering" "peer_to_networking" {
  name                      = "peer-peer-to-networking"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.peer.name
  remote_virtual_network_id = azurerm_virtual_network.networking.id
}
