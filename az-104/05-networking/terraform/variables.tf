variable "location" {
  description = "Azure region for networking resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the existing resource group"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space of the virtual network"
  type        = list(string)
}

variable "web_subnet_name" {
  description = "Name of the web subnet"
  type        = string
}

variable "web_subnet_prefix" {
  description = "Address prefix of the web subnet"
  type        = string
}

variable "app_subnet_name" {
  description = "Name of the application subnet"
  type        = string
}

variable "app_subnet_prefix" {
  description = "Address prefix of the application subnet"
  type        = string
}

variable "private_endpoints_subnet_name" {
  description = "Name of the private endpoints subnet"
  type        = string
}

variable "private_endpoints_subnet_prefix" {
  description = "Address prefix of the private endpoints subnet"
  type        = string
}

variable "web_nsg_name" {
  description = "Name of the network security group for the web subnet"
  type        = string
}

variable "app_route_table_name" {
  description = "Name of the route table for the app subnet"
  type        = string
}

variable "tags" {
  description = "Common tags applied to Azure resources"
  type        = map(string)
}

variable "nat_gateway_name" {
  description = "Name of the NAT Gateway"
  type        = string
}

variable "nat_public_ip_name" {
  description = "Name of the public IP used by the NAT Gateway"
  type        = string
}

variable "peer_vnet_name" {
  description = "Name of the peer virtual network"
  type        = string
}

variable "peer_vnet_address_space" {
  description = "Address space of the peer virtual network"
  type        = list(string)
}

variable "peer_subnet_name" {
  description = "Name of the subnet in the peer virtual network"
  type        = string
}

variable "peer_subnet_prefix" {
  description = "Address prefix of the peer subnet"
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account used for the Private Endpoint lab"
  type        = string
}

variable "private_endpoint_name" {
  description = "Name of the Storage Account Private Endpoint"
  type        = string
}

variable "private_dns_zone_name" {
  description = "Private DNS zone name for Azure Blob Storage"
  type        = string
}
