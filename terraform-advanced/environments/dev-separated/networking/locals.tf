locals {
  environment = "DEV"
  name_prefix = "terraform-${lower(local.environment)}"

  vm_sizes = {
    dev  = "Standard_B1s"
    test = "Standard_B2s"
    prod = "Standard_D2s_v5"
  }

  vm_size = lookup(local.vm_sizes, lower(local.environment), "Standard_B1s")

  security_rules = {
    http = {
      port = 80
    }

    https = {
      port = 443
    }
  }
}
