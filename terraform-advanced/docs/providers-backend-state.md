# Terraform Advanced – Providers, Remote Backend and State Management

## 1. Objective

This lesson explains how Terraform connects to Azure,
where it stores infrastructure state and how state
is managed safely.

Topics covered:

- Terraform providers
- Provider version constraints
- AzureRM provider configuration
- Local and remote state
- Azure Storage backend
- Microsoft Entra ID authentication
- State locking
- State commands
- State security
- Practical troubleshooting

## 2. What Is a Terraform Provider?

A Terraform provider is a plugin that allows Terraform
to interact with an external API or platform.

Examples:

    hashicorp/azurerm
    hashicorp/aws
    hashicorp/azuread
    hashicorp/kubernetes

Our project uses the AzureRM provider to manage
Microsoft Azure infrastructure.

Terraform Core determines the execution plan.

The provider communicates with Azure APIs to perform
the requested resource operations.

## 3. AzureRM Provider Configuration

Our project contains:

    terraform {
      required_version = ">= 1.5.0"

      required_providers {
        azurerm = {
          source  = "hashicorp/azurerm"
          version = "~> 4.0"
        }
      }
    }

    provider "azurerm" {
      features {}
    }

Explanation:

required_version:
Defines the Terraform CLI version requirement.

required_providers:
Declares the providers required by the configuration.

source:
Identifies the provider's registry namespace and name.

version:
Defines the acceptable provider versions.

features {}:
Required AzureRM provider configuration block.

## 4. Understanding Version Constraints

Our configuration uses:

    version = "~> 4.0"

This allows compatible AzureRM 4.x releases,
but excludes version 5.0 and later.

For example:

    4.0.0   allowed
    4.20.0  allowed
    4.99.0  allowed
    5.0.0   not allowed

The constraint:

    required_version = ">= 1.5.0"

Allows Terraform CLI version 1.5.0 or newer.

IMPORTANT:

A minimum version constraint does not guarantee
compatibility with every future Terraform release.

Provider upgrades should be tested before production use.

## 5. Terraform Provider vs Azure Resource Provider

These are two different concepts.

Terraform provider:

    hashicorp/azurerm

A plugin used by Terraform to interact with Azure.

Azure resource provider:

    Microsoft.Network
    Microsoft.Compute
    Microsoft.Storage

An Azure service namespace responsible for resource types.

Example execution flow:

    terraform apply
          |
          v
    Terraform Core
          |
          v
    AzureRM Terraform Provider
          |
          v
    Azure Resource Manager API
          |
          v
    Azure Resource Provider
          |
          v
    Azure Resource

Azure Resource Manager performs authorization,
validation and orchestration of Azure resource requests.

The relevant Azure resource provider handles
operations for its resource types.

A subscription may need the appropriate Azure
resource provider namespace registered.

## 6. What Is Terraform State?

Terraform state records the relationship between
Terraform resource addresses and managed infrastructure.

Example:

    module.networking.azurerm_virtual_network.this

This address identifies a resource managed by Terraform.

The state contains information such as:

- Resource addresses
- Resource instance identifiers
- Resource attributes
- Dependencies and metadata
- Root output values
- State lineage and serial

Terraform uses state when calculating plans.

State is not simply a list of resources.

It is a critical part of Terraform infrastructure management.

## 7. Local State

By default, Terraform uses a local backend.

The state is normally stored in:

    terraform.tfstate

Advantages:

- Simple to configure
- Useful for learning
- No remote storage dependency

Limitations:

- Difficult to share safely
- Local file can be lost
- Poor fit for collaborative deployments
- No Azure Storage remote locking

Local state is appropriate for small experiments,
but remote state is usually preferred for team workflows.

## 8. Azure Storage Remote Backend

Our project uses Azure Storage to store Terraform state.

Example from DEV networking:

    terraform {
      backend "azurerm" {
        resource_group_name  = "rg-terraform-state"
        storage_account_name = "sttfstatezivkovic26"
        container_name       = "tfstate"
        key                  = "dev-networking.tfstate"
        use_azuread_auth     = true
      }
    }

The backend configuration tells Terraform where
to read and write state.

The storage account and container already need to exist
before Terraform can initialize this backend.

The backend infrastructure must be managed separately
from resources whose state is stored inside it.

## 9. Understanding Backend Arguments

resource_group_name:

    rg-terraform-state

Resource group containing the backend storage account.

storage_account_name:

    sttfstatezivkovic26

Azure Storage account holding state blobs.

container_name:

    tfstate

Blob container containing Terraform state files.

key:

    dev-networking.tfstate

Name of the state blob for this root configuration.

use_azuread_auth:

    true

Enables Microsoft Entra ID authentication
for Azure Storage data-plane operations.

The authenticated identity must have appropriate
Azure Storage permissions.

## 10. Our Terraform State Files

During our labs, we used these backend keys:

Original DEV:

    dev.tfstate

TEST:

    test.tfstate

Separated DEV networking:

    dev-networking.tfstate

Separated DEV compute:

    dev-compute.tfstate

Each key identifies a different state blob.

The separate DEV networking and compute states
were created during Lesson 11.

IMPORTANT:

A different state key does not automatically mean
a different Azure subscription or access boundary.

## 11. Authentication and Authorization

The AzureRM provider and AzureRM backend have
related but distinct authentication needs.

The provider communicates with Azure Resource Manager
to manage infrastructure.

The backend communicates with Azure Storage
to read and write Terraform state.

An identity may need:

- Azure RBAC permissions for infrastructure operations
- Storage data-plane permissions for backend state access

For example, Storage Blob Data Contributor can be
appropriate for reading and writing state blobs.

Actual permissions should follow least privilege.

IMPORTANT:

Being able to create Azure resources does not
automatically grant permission to read or write blobs.

## 12. Terraform State Locking

State locking prevents multiple Terraform operations
from modifying the same state simultaneously.

The AzureRM backend uses Azure Blob leases
to coordinate state access.

Example scenario:

Engineer A:

    terraform apply

Engineer B:

    terraform apply

If both target the same remote state,
Terraform locking helps prevent concurrent state writes.

Without locking, concurrent modifications can
corrupt state or cause inconsistent infrastructure changes.

IMPORTANT:

Locking protects one state at a time.

Separate states can still have infrastructure dependencies
that require coordination.

## 13. Terraform Initialization

Command:

    terraform init

Terraform initialization prepares the working directory.

It can:

- Initialize the configured backend
- Download required providers
- Initialize referenced modules
- Create local Terraform metadata

When backend settings change, Terraform may require:

    terraform init -reconfigure

This tells Terraform to accept the current backend
configuration without automatically migrating state.

For an intended backend migration, Terraform also supports:

    terraform init -migrate-state

IMPORTANT:

Backend migration must be planned carefully.

Do not use initialization flags without understanding
whether existing state should be moved.

## 14. Important State Commands

List resources:

    terraform state list

Inspect a resource:

    terraform state show RESOURCE_ADDRESS

Download a state snapshot:

    terraform state pull

Save a local backup:

    terraform state pull > state-backup.json

Move a resource address:

    terraform state mv SOURCE_ADDRESS DESTINATION_ADDRESS

Stop tracking a resource:

    terraform state rm RESOURCE_ADDRESS

Push a prepared snapshot:

    terraform state push PATH_TO_STATE_FILE

IMPORTANT:

state rm does not delete the actual cloud resource.

state mv changes Terraform state ownership or addresses.

state push can replace a backend state snapshot
and must be used with extreme care.

## 15. Understanding terraform plan

Command:

    terraform plan

Terraform compares:

- Current configuration
- Existing state
- Information obtained from providers

It calculates the proposed infrastructure changes.

Common plan actions:

    +    create
    ~    update in-place
    -    destroy
    -/+  destroy then create replacement
    +/-  create replacement then destroy

Always review the plan before applying changes.

## 16. Understanding terraform apply

Command:

    terraform apply

Terraform creates an execution plan and,
after approval when required, performs the changes.

The provider sends operations to Azure APIs.

After successful operations, Terraform updates state
to reflect the managed infrastructure.

Terraform state should remain consistent with
the actual infrastructure.

## 17. Understanding terraform destroy

Command:

    terraform destroy

Terraform plans to delete resources tracked by
the active configuration and state.

IMPORTANT:

Destroying infrastructure is not the same
as deleting a Terraform state file.

Deleting a state file can leave real infrastructure
running without Terraform tracking it.

Destroy operations must be reviewed carefully,
especially in production.

## 18. State Security

Terraform state can contain sensitive values.

Even values marked sensitive in Terraform output
may still be present in state.

Recommended practices:

- Store state in secured remote storage.
- Use Microsoft Entra ID authentication where appropriate.
- Apply least-privilege RBAC.
- Restrict backend network access where feasible.
- Enable appropriate storage protection and recovery.
- Avoid storing credentials directly in Terraform code.
- Never commit state files to GitHub.
- Protect state backups.
- Audit access to production state.

Sensitive values should be managed using
appropriate secret-management practices.

## 19. State Backups

During our migration lab, we created a local backup:

    terraform state pull > dev-state-backup.json

We also created a backup of the original remote
Azure Storage state blob before retiring it.

Backups are essential because state corruption
or accidental replacement can disrupt infrastructure management.

However, backups must be secured like the original state.

## 20. Troubleshooting Examples

### Problem: Backend initialization fails

Possible causes:

- Incorrect storage account name
- Incorrect container name
- Missing backend permissions
- Authentication failure
- Network access restrictions

Check the configured backend and identity permissions.

### Problem: Provider initialization fails

Possible causes:

- Unsupported Terraform version
- Provider version constraint conflict
- Provider download failure
- Invalid provider configuration

Useful commands:

    terraform version
    terraform init
    terraform validate

### Problem: State lock error

Possible causes:

- Another Terraform operation is active
- A previous operation was interrupted
- A stale lock remains

First confirm that no other operation is running.

Do not forcibly unlock a state without verifying
that the lock is genuinely stale.

### Problem: Terraform wants to recreate existing resources

Possible causes:

- Wrong backend key
- Wrong workspace
- Missing state records
- Changed resource addresses
- Configuration drift

Useful commands:

    terraform state list
    terraform plan

Never apply an unexpected recreation plan
without investigating the cause.

## 21. Real-World DevOps Usage

Remote state management is important for:

- Team collaboration
- CI/CD pipelines
- Infrastructure ownership
- Disaster recovery planning
- State migration
- Access control
- Change review
- Production deployment safety

In enterprise environments, remote state should be
treated as critical infrastructure.

## 22. Key Takeaways

1. Terraform providers interact with external APIs.
2. The AzureRM provider is different from Azure resource providers.
3. Terraform state maps configuration to managed resources.
4. Remote state supports collaborative infrastructure management.
5. Azure Storage can store Terraform state blobs.
6. Different backend keys create separate states.
7. Azure Blob leases support state locking.
8. Provider and backend permissions are distinct concerns.
9. State operations must be performed carefully.
10. State files and backups must be protected.
11. terraform plan should be reviewed before apply.
12. State separation and migration require verification.
