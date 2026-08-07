# Azure Resource Providers

## Overview

Azure Resource Providers are Azure services responsible for exposing and managing specific types of Azure resources through Azure Resource Manager.

ARM coordinates deployment requests and forwards service-specific operations to the appropriate Resource Provider.

## Common Resource Providers

| Resource Provider | Example Resources |
|---|---|
| `Microsoft.Compute` | Virtual Machines, Managed Disks, VM Scale Sets |
| `Microsoft.Network` | VNets, Subnets, NSGs, Load Balancers |
| `Microsoft.Storage` | Storage Accounts |
| `Microsoft.KeyVault` | Key Vaults |
| `Microsoft.Sql` | Azure SQL |
| `Microsoft.Web` | App Service |
| `Microsoft.ContainerService` | AKS |
| `Microsoft.Insights` | Azure Monitor resources |
| `Microsoft.OperationalInsights` | Log Analytics |

## Resource Provider vs Resource Type

A Resource Provider can expose multiple resource types.

Example provider:

```text
Microsoft.Compute
```

Example resource types:

```text
virtualMachines
disks
snapshots
virtualMachineScaleSets
```

A fully qualified resource type combines both:

```text
Microsoft.Compute/virtualMachines
```

Another example:

```text
Microsoft.Storage/storageAccounts
```

## Resource Provider Registration

A subscription may need to be registered for a Resource Provider before resources from that provider can be deployed.

Example:

```bash
az provider register \
  --namespace Microsoft.ContainerService
```

Check the registration state:

```bash
az provider show \
  --namespace Microsoft.ContainerService \
  --query registrationState
```

Common states include:

```text
Registered
Registering
NotRegistered
```

Registration enables the subscription to use the provider.

It does not create any Azure resources.

## Terraform Provider vs Azure Resource Provider

These are different concepts.

### Terraform Provider

Example:

```hcl
provider "azurerm" {
  features {}
}
```

The Terraform Azure provider allows Terraform to communicate with Azure APIs and translate Terraform resource configuration into appropriate API operations.

### Azure Resource Provider

Example:

```text
Microsoft.Compute
```

This is an Azure platform service that exposes and manages Azure resource types.

Simplified relationship:

```text
Terraform
    │
    ▼
Terraform Azure Provider
    │
    ▼
Azure management APIs / ARM
    │
    ▼
Azure Resource Provider
    │
    ▼
Azure Resource
```

## Example: Creating a Storage Account

Suppose Terraform contains:

```hcl
resource "azurerm_storage_account" "example" {
  # configuration
}
```

A simplified deployment flow is:

```text
terraform apply
      │
      ▼
Terraform Azure Provider
      │
      ▼
Azure Resource Manager
      │
      ├── Authentication / identity validation
      ├── Authorization
      ├── Request validation
      └── Deployment coordination
      │
      ▼
Microsoft.Storage
      │
      ▼
Storage Account
      │
      ▼
Result returned to Terraform
      │
      ▼
Terraform updates its state
```

The component responsible for implementing the Storage Account resource operation is the `Microsoft.Storage` Resource Provider.

ARM coordinates the management request.

## Provider Registration Failure

If a required provider is unavailable or not registered for the subscription, a deployment can fail with an error indicating that the subscription is not registered for the namespace.

For example, attempting to deploy AKS may require:

```text
Microsoft.ContainerService
```

The provider can then be registered before retrying the deployment.

## Interview Questions

1. What is an Azure Resource Provider?
2. What is the difference between a Resource Provider and a Resource Type?
3. Why might a Resource Provider need to be registered?
4. What is the difference between the Terraform Azure provider and an Azure Resource Provider?
5. Which Resource Provider manages Virtual Machines?
6. Which Resource Provider manages Storage Accounts?
7. Which Resource Provider manages AKS?
8. What happens if a required Resource Provider is not registered?
9. Which component ultimately handles a Storage Account resource operation: Terraform, ARM, or `Microsoft.Storage`?

## Key Takeaways

- Resource Providers expose and manage specific Azure resource types.
- ARM coordinates requests and routes them to Resource Providers.
- A Resource Provider can expose multiple Resource Types.
- Provider registration may be required at subscription scope.
- Terraform providers and Azure Resource Providers are different concepts.
- Terraform manages its own state after Azure returns the result of an operation.
