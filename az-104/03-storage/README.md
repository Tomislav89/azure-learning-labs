# AZ-104 — Azure Storage

Hands-on lab covering Azure Storage concepts, security, networking, Azure CLI, and Terraform.

## Topics Covered

- Azure Storage Accounts
- Blob Storage and containers
- Azure Files and SMB
- Storage access tiers
- Storage redundancy
- Microsoft Entra ID and RBAC for storage
- Shared Access Signatures (SAS)
- Blob versioning and soft delete
- Lifecycle management
- Private Endpoints
- Private DNS Zones
- Azure CLI
- Terraform import and infrastructure management

## Lab Architecture

The lab uses a StorageV2 account with:

- Standard performance
- LRS redundancy
- Private Blob container
- Azure File Share
- Lifecycle policy for Blob Storage
- Private Endpoint for the Blob service
- Private DNS integration with an existing VNet

```text
vnet-app-dev
└── snet-private-endpoints
    └── Private Endpoint
        └── Blob service
            └── staz104storage1212

Private DNS Zone
privatelink.blob.core.windows.net
        │
        └── linked to vnet-app-dev
```

## Storage Resources

### Storage Account

The lab uses the following Storage Account:

```text
staz104storage1212
```

Configuration:

- StorageV2
- Standard performance tier
- LRS redundancy
- North Europe region
- Anonymous Blob access disabled

### Blob Storage

A private Blob container was configured:

```text
az104-documents
```

The container was used to practice:

- Blob upload and download
- Microsoft Entra ID authentication
- Storage data-plane RBAC
- Blob versioning
- Soft delete and recovery
- Access tiers
- Lifecycle management

### Azure Files

An Azure File Share was configured:

```text
az104-share
```

The share was mounted from Linux/WSL using SMB 3.0.

This demonstrated the difference between:

```text
Blob Storage
└── Container
    └── Blob

Azure Files
└── File Share
    └── File
```

## Lifecycle Management

A lifecycle management policy was configured for Blob Storage.

Block blobs that have not been modified for more than 30 days are automatically moved to the Cool tier.

```text
Block Blob
    │
    │ > 30 days since modification
    ▼
Cool tier
```

## Private Networking

A Private Endpoint was configured for the Blob service.

```text
vnet-app-dev
└── snet-private-endpoints
    └── pe-storage-blob-dev
        └── Private IP
            └── Azure Blob Storage
```

The Private Endpoint provides private connectivity to the Blob service using a private IP address from the VNet.

## Private DNS

The following Private DNS Zone is used:

```text
privatelink.blob.core.windows.net
```

The DNS zone allows the Blob Storage hostname to resolve to the private IP address of the Private Endpoint.

The Private DNS Zone is linked to:

```text
vnet-app-dev
```

Conceptually:

```text
Application / VM
       │
       │ Blob Storage hostname
       ▼
Private DNS Zone
       │
       │ DNS resolution
       ▼
Private Endpoint IP
       │
       ▼
Azure Blob Storage
```

## Terraform

Terraform manages:

- Storage Account
- Blob Container
- Azure File Share
- Storage Lifecycle Management Policy
- Private DNS Zone
- Private DNS VNet Link
- Blob Private Endpoint

Existing infrastructure is referenced through Terraform data sources:

- Resource Group
- Virtual Network
- Subnet

### Terraform Data Sources

Existing resources that are not managed by this Terraform configuration are referenced using `data` blocks.

Examples:

```hcl
data "azurerm_resource_group" "app_dev" {
  name = "rg-app-dev"
}

data "azurerm_virtual_network" "app_dev" {
  name                = "vnet-app-dev"
  resource_group_name = data.azurerm_resource_group.app_dev.name
}

data "azurerm_subnet" "private_endpoints" {
  name                 = "snet-private-endpoints"
  virtual_network_name = data.azurerm_virtual_network.app_dev.name
  resource_group_name  = data.azurerm_resource_group.app_dev.name
}
```

These resources already existed and are only read by this Terraform configuration.

### Terraform Import

Several Azure resources were initially created manually through the Azure Portal and later imported into Terraform.

The workflow used was:

```text
Existing Azure resource
        │
        ▼
Write matching HCL
        │
        ▼
terraform import
        │
        ▼
terraform plan
        │
        ▼
Reconcile configuration drift
        │
        ▼
No changes
```

This demonstrated how Terraform can adopt existing brownfield infrastructure without recreating it.

## Final Terraform State

The final Terraform state contains:

```text
data.azurerm_resource_group.app_dev
data.azurerm_subnet.private_endpoints
data.azurerm_virtual_network.app_dev

azurerm_private_dns_zone.blob
azurerm_private_dns_zone_virtual_network_link.blob
azurerm_private_endpoint.storage_blob
azurerm_storage_account.storage
azurerm_storage_container.documents
azurerm_storage_management_policy.lifecycle
azurerm_storage_share.files
```

Final validation:

```text
No changes. Your infrastructure matches the configuration.
```

## Key Concepts Practiced

This lab provided hands-on experience with:

- Azure Storage architecture
- Blob Storage vs Azure Files
- Storage authentication and authorization
- Management-plane vs data-plane permissions
- Microsoft Entra ID authentication
- Azure Storage RBAC
- Shared Access Signatures
- Storage redundancy
- Storage access tiers
- Blob versioning and recovery
- Lifecycle management
- Private Endpoints
- Private DNS resolution
- Azure CLI
- Terraform data sources
- Terraform resource imports
- Terraform state
- Configuration drift

## Repository Structure

```text
03-storage/
├── README.md
├── LAB.md
└── terraform/
    ├── main.tf
    ├── providers.tf
    └── .terraform.lock.hcl
```

Terraform state files are intentionally excluded from Git.

Detailed implementation notes and validation steps are documented in [LAB.md](LAB.md).
