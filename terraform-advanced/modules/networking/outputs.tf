output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.this.id
}

output "web_subnet_id" {
  description = "ID of the web subnet"
  value       = azurerm_subnet.this["web"].id
}

output "app_subnet_id" {
  description = "ID of the application subnet"
  value       = azurerm_subnet.this["app"].id
}
