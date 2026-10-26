# Terraform Networking Module

## 1. Purpose

This module creates an Azure Virtual Network (VNet) and multiple subnets.

The goal is to write networking infrastructure once and reuse it across
different environments such as DEV, TEST and PROD.

## 2. Project Files

- main.tf: Defines Azure networking resources.
- variables.tf: Defines input variables.
- outputs.tf: Exposes resource IDs.

## 3. Virtual Network

The main.tf file contains:

    resource "azurerm_virtual_network" "this" {
      name                = var.vnet_name
      address_space       = var.address_space
      location            = var.location
      resource_group_name = var.resource_group_name
    }

Explanation:

- name: Name of the virtual network.
- address_space: IP address range, for example 10.10.0.0/16.
- location: Azure region.
- resource_group_name: Resource group containing the VNet.

Values are received through input variables.

## 4. Creating Subnets with for_each

The module uses:

    resource "azurerm_subnet" "this" {
      for_each = var.subnets

      name                 = "snet-${each.key}"
      resource_group_name  = var.resource_group_name
      virtual_network_name = azurerm_virtual_network.this.name
      address_prefixes     = [each.value.address_prefix]
    }

The for_each expression creates one subnet for each entry in the map.

Example input:

    subnets = {
      web = {
        address_prefix = "10.10.1.0/24"
        service        = "web"
      }

      app = {
        address_prefix = "10.10.2.0/24"
        service        = "app"
      }
    }

Terraform creates:

- azurerm_subnet.this["web"] -> snet-web
- azurerm_subnet.this["app"] -> snet-app

each.key represents the map key, such as web or app.

each.value represents the object associated with that key.

The service field is defined in the input type but is not currently
used to configure an Azure resource.

## 5. Input Variables

vnet_name:
- Type: string
- Purpose: Virtual network name.

address_space:
- Type: list(string)
- Purpose: VNet IP address ranges.

location:
- Type: string
- Purpose: Azure region.

resource_group_name:
- Type: string
- Purpose: Resource group name.

subnets:
- Type: map(object)
- Purpose: Subnet configuration.

Each subnet object contains address_prefix and service.

## 6. Outputs

vnet_id:
- Returns the Azure resource ID of the VNet.

web_subnet_id:
- Returns the Azure resource ID of the web subnet.

app_subnet_id:
- Returns the Azure resource ID of the application subnet.

The current module requires web and app keys in the subnets map
because its outputs reference those keys directly.

## 7. Using the Module

A root Terraform configuration can call the module:

    module "networking" {
      source = "../../modules/networking"

      vnet_name           = "vnet-dev"
      address_space       = ["10.10.0.0/16"]
      location            = "northeurope"
      resource_group_name = "rg-terraform-dev"

      subnets = {
        web = {
          address_prefix = "10.10.1.0/24"
          service        = "web"
        }

        app = {
          address_prefix = "10.10.2.0/24"
          service        = "app"
        }
      }
    }

This example assumes that the resource group already exists.

The relative source path must match the location of the root module.

## 8. Terraform Commands

Run these commands from the root configuration, not directly
from the reusable module directory:

    terraform init
    terraform fmt -recursive
    terraform validate
    terraform plan
    terraform apply

Explanation:

terraform init:
Downloads providers and initializes the working directory.

terraform fmt:
Formats Terraform configuration files.

terraform validate:
Checks configuration validity.

terraform plan:
Shows proposed infrastructure changes.

terraform apply:
Creates or updates infrastructure after confirmation.

terraform destroy:
Destroys resources managed by the current configuration.

Always review the plan before applying or destroying resources.

## 9. Real-World DevOps Usage

Reusable networking modules are useful when:

- Multiple environments need similar network architecture.
- Teams want standardized resource naming.
- Network configurations must be maintained centrally.
- Compute infrastructure needs subnet IDs from networking outputs.

## 10. Key Takeaways

- A module is reusable Terraform code.
- Variables customize module behavior.
- for_each creates multiple resources from a collection.
- Outputs expose information to other Terraform configurations.
- Reusing modules reduces duplicated infrastructure code.
