# Terraform Advanced – DEV and TEST Environments

## 1. Purpose

This lesson explains how to organize Terraform infrastructure
for multiple environments such as DEV, TEST and PROD.

The main goals are:

- Reuse the same Terraform modules.
- Configure environments independently.
- Keep environment state files separate.
- Reduce the risk of accidental changes across environments.
- Support different infrastructure configurations.

## 2. What Is a Terraform Environment?

An environment is a separate deployment context.

Typical environments include:

DEV:
Used for development and experimentation.

TEST:
Used for testing infrastructure and applications.

PROD:
Used for production workloads.

Terraform does not automatically create environments
just because directories are named dev, test or prod.

Environment separation comes from configuration,
state isolation, credentials and deployment workflows.

## 3. Our Project Structure

The Terraform project contains:

    terraform-modules/
    |
    +-- modules/
    |   +-- networking/
    |   +-- compute/
    |
    +-- environments/
        +-- dev-legacy/
        +-- test/
        +-- dev-separated/
            +-- networking/
            +-- compute/

The original DEV configuration was later archived
as dev-legacy after state separation.

The final DEV architecture uses separate networking
and compute root configurations.

## 4. Reusing Terraform Modules

A Terraform module is reusable infrastructure code.

For example, the networking module defines:

    resource "azurerm_virtual_network" "this" {
      name                = var.vnet_name
      address_space       = var.address_space
      location            = var.location
      resource_group_name = var.resource_group_name
    }

The module does not hardcode an environment name.

Instead, a root configuration passes values such as:

    vnet_name     = "vnet-dev"
    address_space = ["10.10.0.0/16"]

Another environment could use:

    vnet_name     = "vnet-test"
    address_space = ["10.20.0.0/16"]

These are examples of environment-specific values.

The same module can create different infrastructure
without duplicating the resource definition.

## 5. Root Module vs Reusable Module

A reusable module defines infrastructure components.

A root module calls reusable modules and supplies
the values needed for a particular deployment.

Example:

    module "networking" {
      source = "../../../modules/networking"

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

The source path must be calculated relative to the
directory containing the root configuration.

The example assumes the resource group already exists.

## 6. Environment-Specific Configuration

Different environments may have different:

- Resource names
- Network address spaces
- Subnet ranges
- Resource group names
- Azure subscriptions
- Resource sizes
- Access permissions
- Terraform state locations

For example:

DEV:
    vnet-dev
    10.10.0.0/16

TEST:
    vnet-test
    10.20.0.0/16

These values illustrate the concept.
Actual settings must be checked in the environment files.

## 7. Separating Terraform State

Terraform state tracks resources managed by a configuration.

If DEV and TEST share the same state accidentally,
changes intended for one environment may affect another.

Our earlier lab used separate backend keys:

    dev.tfstate
    test.tfstate

Later, the DEV state was separated further into:

    dev-networking.tfstate
    dev-compute.tfstate

This provides independent state management for
different infrastructure components.

State separation does not automatically guarantee
security isolation.

Access controls and backend permissions must also
be configured appropriately.

## 8. Azure Storage Remote Backend

Our project uses an Azure Storage backend.

Example configuration:

    terraform {
      backend "azurerm" {
        resource_group_name  = "rg-terraform-state"
        storage_account_name = "sttfstatezivkovic26"
        container_name       = "tfstate"
        key                  = "dev-networking.tfstate"
        use_azuread_auth     = true
      }
    }

Explanation:

resource_group_name:
Resource group containing the storage account.

storage_account_name:
Azure Storage account containing Terraform state.

container_name:
Blob container containing state files.

key:
Blob name identifying the state for this configuration.

use_azuread_auth:
Uses Microsoft Entra ID authentication for the
Azure Storage data plane.

The identity must have appropriate permissions.

## 9. Why Separate State Matters

Consider two independent environments.

If a developer changes DEV networking,
Terraform should not modify TEST infrastructure.

Separate state files help Terraform track each
environment independently.

Benefits include:

- Smaller Terraform plans
- Independent deployments
- Reduced blast radius
- Easier ownership boundaries
- More predictable infrastructure changes

However, independent state files also introduce
dependencies between configurations.

Those dependencies must be managed explicitly.

## 10. Terraform Commands

Navigate to the required root configuration.

Example:

    cd environments/dev-separated/networking

Initialize Terraform:

    terraform init

Validate the configuration:

    terraform validate

Preview changes:

    terraform plan

Apply changes:

    terraform apply

Remove managed resources:

    terraform destroy

IMPORTANT:

Always verify the working directory and backend key
before running apply or destroy.

The same commands can affect different infrastructure
depending on the active root configuration and backend.

## 11. Deployment Order

Our final DEV architecture separates networking and compute.

Deployment order:

    1. Networking
    2. Compute

Networking creates the subnet.

Compute reads the subnet ID from networking state.

Destruction order:

    1. Compute
    2. Networking

This prevents attempting to remove network infrastructure
while compute resources still depend on it.

Separate Terraform configurations do not automatically
share a dependency graph.

The deployment workflow must enforce the correct order.

## 12. Real-World DevOps Usage

Enterprise Terraform projects often separate environments
using different root configurations, backend state files,
subscriptions and deployment permissions.

For example:

- Developers can deploy to DEV.
- CI/CD pipelines can deploy to TEST.
- Production changes can require approvals.
- Production state can have more restrictive access.

Using the same reusable modules helps maintain
consistent infrastructure patterns.

## 13. Lessons Learned

- Terraform modules make infrastructure reusable.
- Root configurations provide environment-specific values.
- Separate backend keys create separate Terraform states.
- DEV and TEST should not accidentally share state.
- State separation reduces the scope of changes.
- Infrastructure dependencies still require coordination.
- Deployment permissions are as important as state separation.

## 14. Lab Cleanup

During our Terraform Advanced labs, the deployed
DEV and TEST infrastructure was removed after testing.

The DEV networking and compute resources were destroyed
in dependency order.

The remote state backend was retained separately.

Keeping the backend allows future labs to reuse
the existing Terraform state infrastructure.
