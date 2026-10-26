# Terraform Advanced – Variables, Outputs and Data Sources

## 1. Objective

This lesson explains how Terraform configurations exchange values,
reuse infrastructure modules and reference existing resources.

Topics:

- Input variables
- Variable types
- Maps and objects
- Module inputs
- Output values
- Data sources
- Remote state outputs
- Dependencies between configurations

## 2. Input Variables

Input variables allow a Terraform module to receive values
from its calling configuration.

Our networking module defines:

    variable "vnet_name" {
      type = string
    }

    variable "address_space" {
      type = list(string)
    }

    variable "location" {
      type = string
    }

    variable "resource_group_name" {
      type = string
    }

The module references these values using:

    var.vnet_name
    var.address_space
    var.location
    var.resource_group_name

Input variables help us avoid hardcoding environment-specific
values inside reusable modules.

## 3. Variable Types

Terraform supports several variable types.

Examples:

    string

A text value.

    number

A numeric value.

    bool

A true or false value.

    list(string)

An ordered collection of strings.

    map(string)

A collection of named string values.

    object({
      address_prefix = string
      service        = string
    })

An object with defined attributes and types.

## 4. Maps of Objects

Our networking module uses:

    variable "subnets" {
      type = map(object({
        address_prefix = string
        service        = string
      }))
    }

This means that subnets is a map.

Each map entry contains an object with:

    address_prefix
    service

Example from DEV:

    subnets = {
      web = {
        address_prefix = "10.10.1.0/24"
        service        = "frontend"
      }

      app = {
        address_prefix = "10.10.2.0/24"
        service        = "application"
      }
    }

The map keys are:

    web
    app

Each entry has a subnet address range and a service label.

IMPORTANT:

The current networking module uses address_prefix
to create subnets.

The service attribute is defined and supplied,
but is not currently used by the subnet resource.

## 5. Creating Resources with for_each

Our networking module contains:

    resource "azurerm_subnet" "this" {
      for_each = var.subnets

      name                 = "snet-${each.key}"
      resource_group_name  = var.resource_group_name
      virtual_network_name = azurerm_virtual_network.this.name
      address_prefixes     = [each.value.address_prefix]
    }

Terraform creates one subnet instance for each map entry.

For example:

    web        -> snet-web
    app        -> snet-app
    db         -> snet-db
    management -> snet-management

Each instance receives its own address prefix.

The resulting resource addresses include:

    azurerm_subnet.this["web"]
    azurerm_subnet.this["app"]

Using stable map keys helps Terraform track individual
instances consistently.

## 6. Module Inputs

Our DEV networking configuration calls the module:

    module "networking" {
      source = "../../../modules/networking"

      vnet_name           = "vnet-dev"
      address_space       = ["10.10.0.0/16"]
      location            = azurerm_resource_group.this.location
      resource_group_name = azurerm_resource_group.this.name

      subnets = {
        web = {
          address_prefix = "10.10.1.0/24"
          service        = "frontend"
        }

        app = {
          address_prefix = "10.10.2.0/24"
          service        = "application"
        }

        db = {
          address_prefix = "10.10.3.0/24"
          service        = "database"
        }

        management = {
          address_prefix = "10.10.4.0/24"
          service        = "management"
        }
      }
    }

The root configuration supplies values.

The module uses those values to create Azure resources.

This is how the same networking module can support
different environments.

## 7. Terraform Outputs

Outputs expose values from a Terraform module.

Our networking module defines:

    output "app_subnet_id" {
      value = azurerm_subnet.this["app"].id
    }

This returns the Azure resource ID of the application subnet.

A root module can access it using:

    module.networking.app_subnet_id

Outputs can also be used by other Terraform configurations
when exposed as root outputs in remote state.

## 8. Module Outputs vs Root Outputs

A reusable module output:

    output "app_subnet_id" {
      value = azurerm_subnet.this["app"].id
    }

Exposes a value to the calling module.

Our DEV networking root configuration also defines:

    output "app_subnet_id" {
      description = "ID of the DEV application subnet"
      value       = module.networking.app_subnet_id
    }

This exposes the value as a root output.

Root outputs are stored in Terraform state and can be
read by terraform_remote_state.

A child module output is not automatically a root output.

## 9. What Is a Data Source?

A Terraform data source reads information about
existing infrastructure or external data.

It does not create the resource being queried.

For example:

    data "azurerm_resource_group" "dev" {
      name = "rg-terraform-dev"
    }

This reads an existing Azure resource group.

We can then access:

    data.azurerm_resource_group.dev.name
    data.azurerm_resource_group.dev.location

The data source depends on the resource group existing.

If the resource group is missing, the lookup fails.

## 10. Resource vs Data Source

Resource block:

    resource "azurerm_resource_group" "this" {
      name     = "rg-terraform-dev"
      location = "North Europe"
    }

Terraform manages the resource's lifecycle.

Data source:

    data "azurerm_resource_group" "dev" {
      name = "rg-terraform-dev"
    }

Terraform reads an existing resource.

The data source does not take ownership of that
resource's lifecycle.

## 11. Reading Remote Terraform State

Our DEV compute configuration uses:

    data "terraform_remote_state" "networking" {
      backend = "azurerm"

      config = {
        resource_group_name  = "rg-terraform-state"
        storage_account_name = "sttfstatezivkovic26"
        container_name       = "tfstate"
        key                  = "dev-networking.tfstate"
        use_azuread_auth     = true
      }
    }

This reads the networking root outputs from:

    dev-networking.tfstate

The compute configuration can access:

    data.terraform_remote_state.networking.outputs.app_subnet_id

Explanation:

data:
Declares a data source.

terraform_remote_state:
Reads outputs from another Terraform state.

networking:
Local name assigned to this data source.

outputs:
Collection of root outputs in the remote state.

app_subnet_id:
Specific output exported by networking.

IMPORTANT:

terraform_remote_state does not read the other
configuration's outputs.tf file directly.

It reads values stored in the state snapshot.

## 12. Passing Remote State Values to a Module

Our compute configuration contains:

    module "compute" {
      source = "../../../modules/compute"

      nic_name            = "nic-app-dev"
      location            = data.azurerm_resource_group.dev.location
      resource_group_name = data.azurerm_resource_group.dev.name
      subnet_id           = data.terraform_remote_state.networking.outputs.app_subnet_id
    }

The compute module receives:

- Network interface name
- Azure location
- Resource group name
- Application subnet ID

It uses the subnet ID to create a network interface.

The current compute module does not create
an Azure virtual machine.

## 13. Dependencies Between Separate States

Our final DEV architecture has two independent states.

Networking:

    dev-networking.tfstate

Compute:

    dev-compute.tfstate

The compute configuration needs a subnet created
by networking.

Deployment order:

    1. Networking
    2. Compute

Destruction order:

    1. Compute
    2. Networking

Terraform does not automatically coordinate apply
and destroy operations across independent root configurations.

A CI/CD pipeline or deployment procedure must
enforce the correct ordering.

## 14. Security Considerations

Reading Terraform remote state requires access
to the underlying state snapshot.

Even when terraform_remote_state exposes only root outputs
to the calling configuration, backend access may permit
reading the complete state.

State can contain sensitive information.

For production systems, consider whether publishing
specific values through a more restricted interface
would be safer than granting access to another state.

Apply least-privilege permissions to the backend.

## 15. Useful Commands

Initialize a configuration:

    terraform init

Validate configuration:

    terraform validate

Preview changes:

    terraform plan

Apply configuration:

    terraform apply

Display root outputs:

    terraform output

Display a specific output:

    terraform output app_subnet_id

Display an output as raw text:

    terraform output -raw app_subnet_id

List tracked resources:

    terraform state list

IMPORTANT:

Commands operate on the currently selected
root configuration, backend and workspace.

## 16. Real-World DevOps Usage

Variables and outputs are fundamental for reusable
Terraform modules.

Data sources help configurations integrate with
infrastructure that already exists.

Remote state outputs can connect separately managed
infrastructure components.

Examples:

- Networking provides subnet IDs.
- Compute consumes subnet IDs.
- Shared infrastructure exposes resource identifiers.
- Applications consume selected infrastructure values.

Clear ownership and dependency management are essential.

## 17. Key Takeaways

1. Variables provide inputs to Terraform modules.
2. Types validate the structure of input values.
3. map(object) supports structured collections.
4. for_each creates instances from collection entries.
5. Outputs expose values from modules.
6. Root outputs can be read through remote state.
7. Data sources read existing information.
8. Data sources do not manage the lifecycle of queried resources.
9. Separate Terraform states require explicit coordination.
10. Remote state access must be secured.
