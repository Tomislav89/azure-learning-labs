output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.backup.name
}

output "recovery_services_vault_name" {
  description = "Name of the Recovery Services Vault"
  value       = azurerm_recovery_services_vault.backup.name
}

output "backup_policy_name" {
  description = "Name of the virtual machine backup policy"
  value       = azurerm_backup_policy_vm.backup.name
}

output "protected_vm_name" {
  description = "Name of the virtual machine protected by Azure Backup"
  value       = azurerm_linux_virtual_machine.backup.name
}
