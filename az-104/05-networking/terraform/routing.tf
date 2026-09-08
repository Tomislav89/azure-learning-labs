resource "azurerm_route_table" "app" {
  name                = var.app_route_table_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_route" "block_10_80" {
  name                = "block-10-80"
  resource_group_name = var.resource_group_name
  route_table_name    = azurerm_route_table.app.name
  address_prefix      = "10.80.0.0/16"
  next_hop_type       = "None"
}

resource "azurerm_subnet_route_table_association" "app" {
  subnet_id      = azurerm_subnet.app.id
  route_table_id = azurerm_route_table.app.id
}
