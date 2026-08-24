# AZ-104 Storage — Hands-on Lab

## 1. Objective

The goal of this lab was to practice Azure Storage administration using:

- Azure Portal
- Azure CLI
- Linux/WSL
- Terraform

The lab started with resources created manually in Azure and later transitioned them under Terraform management using `terraform import`.

---

## 2. Storage Account

Storage Account:

```text
staz104storage1212
```

Configuration:

- Region: North Europe
- Performance: Standard
- Redundancy: LRS
- Account kind: StorageV2
- Anonymous Blob access disabled

Validation with Azure CLI:

```bash
az storage account show \
  --name staz104storage1212 \
  --resource-group rg-app-dev \
  --query "{name:name,location:location,sku:sku.name,kind:kind,publicNetworkAccess:publicNetworkAccess}" \
  -o table
```

---

## 3. Blob Storage

Blob container:

```text
az104-documents
```

The container was configured with private access.

Blob upload was tested using Microsoft Entra ID authentication:

```bash
az storage blob upload \
  --account-name staz104storage1212 \
  --container-name az104-documents \
  --name cli-test.txt \
  --file cli-test.txt \
  --auth-mode login
```

Blob listing:

```bash
az storage blob list \
  --account-name staz104storage1212 \
  --container-name az104-documents \
  --auth-mode login \
  --query "[].{Name:name,Tier:properties.blobTier}" \
  -o table
```

This demonstrated the difference between management-plane permissions and Storage data-plane permissions.

---

## 4. Azure Files

Azure File Share:

```text
az104-share
```

SMB connectivity was tested on TCP port 445:

```bash
nc -zv staz104storage1212.file.core.windows.net 445
```

The share was mounted from WSL/Linux using SMB 3.0:

```bash
sudo mount -t cifs \
  //staz104storage1212.file.core.windows.net/az104-share \
  /media/az104-share \
  -o credentials=/etc/smbcredentials/staz104storage1212.cred,vers=3.0
```

Mount validation:

```bash
mount | grep az104-share
ls -la /media/az104-share
```

A test file created through the mounted share was successfully visible in Azure.

> Storage account keys and credential files must never be committed to Git.

---

## 5. Storage Authentication and RBAC

Azure CLI Blob operations were tested using:

```text
--auth-mode login
```

This uses the signed-in Microsoft Entra identity instead of a Storage Account access key.

The lab demonstrated that Azure resource management permissions do not automatically provide Blob data access.

Blob data access requires an appropriate data-plane role such as:

```text
Storage Blob Data Contributor
```

---

## 6. Blob Protection

Blob data protection features covered during the lab:

- Blob versioning
- Soft delete
- Blob recovery
- Private container access

These features provide protection against accidental modification and deletion.

---

## 7. Lifecycle Management

A lifecycle management policy was configured for block blobs.

Rule:

```text
If a block blob has not been modified for more than 30 days
→ move it to the Cool tier
```

Terraform resource:

```hcl
resource "azurerm_storage_management_policy" "lifecycle"
```

The existing lifecycle policy was later imported into Terraform.

---

## 8. Existing Network Infrastructure

The Resource Group, VNet and subnet already existed and are referenced using Terraform data sources.

```hcl
data "azurerm_resource_group" "app_dev"
data "azurerm_virtual_network" "app_dev"
data "azurerm_subnet" "private_endpoints"
```

Using `data` means Terraform reads the existing resource instead of creating or managing its lifecycle from this configuration.

Network structure:

```text
vnet-app-dev
└── snet-private-endpoints
```

---

## 9. Private Endpoint

A Private Endpoint was configured for the Blob service:

```text
pe-storage-blob-dev
```

The Private Endpoint resides in:

```text
snet-private-endpoints
```

and provides private connectivity to the Storage Account Blob service.

The Private Endpoint NIC:

```text
pe-storage-blob-dev-nic
```

received a private IP address from the subnet.

The Storage subresource used by the connection is:

```text
blob
```

Terraform:

```hcl
private_service_connection {
  name                           = "pe-storage-blob-dev"
  private_connection_resource_id = azurerm_storage_account.storage.id
  subresource_names              = ["blob"]
  is_manual_connection           = false
}
```

---

## 10. Private DNS

Private DNS Zone:

```text
privatelink.blob.core.windows.net
```

The Private DNS Zone allows the Blob service hostname to resolve to the private IP address of the Private Endpoint.

The zone was linked to:

```text
vnet-app-dev
```

Conceptually:

```text
VNet workload
     │
     │ Blob hostname
     ▼
Private DNS
     │
     ▼
Private Endpoint IP
     │
     ▼
Blob service
```

---

## 11. Terraform Import

Resources originally created manually were adopted into Terraform using `terraform import`.

General workflow:

```text
Write matching resource block
        ↓
terraform import
        ↓
Terraform state contains resource
        ↓
terraform plan
        ↓
Compare HCL with real Azure configuration
        ↓
Fix differences
        ↓
No changes
```

An important example occurred while importing the Private Endpoint.

Terraform initially proposed:

```text
-/+ destroy and then create replacement
```

because the HCL did not match the existing Azure resource for:

```text
custom_network_interface_name
private_service_connection.name
```

The HCL was corrected to match the existing Azure configuration before running any apply operation.

This avoided unnecessary destruction and recreation of the Private Endpoint.

---

## 12. Terraform State

Final state:

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

```bash
terraform plan
```

Result:

```text
No changes. Your infrastructure matches the configuration.
```

This confirms that the Terraform configuration, Terraform state, and deployed Azure infrastructure are aligned.

---

## 13. Key Takeaways

- A Storage Account can provide multiple services such as Blob and Azure Files.
- Blob containers contain blobs; Azure File Shares contain files.
- Azure RBAC management permissions and Storage data-plane permissions are separate concepts.
- Private Endpoints provide private connectivity to Azure PaaS services using an IP address from a VNet.
- Private DNS resolves Azure service names to Private Endpoint addresses.
- Terraform data sources reference existing infrastructure without managing it.
- `terraform import` adds an existing resource to Terraform state but does not automatically make the HCL match the resource.
- Always inspect `terraform plan` after importing existing infrastructure.
