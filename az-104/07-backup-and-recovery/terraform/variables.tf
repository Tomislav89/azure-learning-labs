variable "location" {
  description = "Azure region for the lab resources"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-backup-tf-dev"
}

variable "vault_name" {
  description = "Name of the Recovery Services Vault"
  type        = string
  default     = "rsv-backup-tf-dev"
}

variable "backup_policy_name" {
  description = "Name of the virtual machine backup policy"
  type        = string
  default     = "backup-policy-daily-tf-dev"
}

variable "vm_name" {
  description = "Name of the virtual machine protected by Azure Backup"
  type        = string
  default     = "vm-backup-tf-dev"
}

variable "admin_username" {
  description = "Administrator username for the Linux virtual machine"
  type        = string
  default     = "azureuser"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "DEV"
}
