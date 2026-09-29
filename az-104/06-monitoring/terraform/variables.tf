variable "resource_group_name" {
  description = "Name of the existing Azure Resource Group"
  type        = string
  default     = "rg-app-dev"
}

variable "location" {
  description = "Azure region for monitoring resources"
  type        = string
  default     = "East US"
}

variable "alert_email" {
  description = "Email address that receives Azure Monitor alerts"
  type        = string
  sensitive   = true
}
