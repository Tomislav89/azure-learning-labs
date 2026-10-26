output "app_subnet_id" {
  description = "ID of the TEST application subnet"
  value       = module.networking.app_subnet_id
}

output "nic_id" {
  description = "ID of the TEST network interface"
  value       = module.compute.nic_id
}
