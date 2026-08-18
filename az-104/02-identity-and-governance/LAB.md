# Identity and Governance — Hands-on Lab

## Objective

Practice the core Azure Identity and Governance concepts using:

- Azure Portal
- Azure CLI
- Terraform

---

## Lab Environment

Resource Group:

`rg-app-dev`

Tags:

- Environment = DEV
- Project = AzureLearning
- CostCenter = LAB
- ManagedBy = Terraform

---

## 1. Microsoft Entra ID

Created users and security groups to practice identity management.

### Groups

- Developers
- Auditors

The Developers group is used to manage developer access collectively instead of assigning permissions individually.

---

## 2. Azure RBAC

Configured role assignments at different scopes.

### Developers

- Role: Contributor
- Scope: `rg-app-dev`

Members of the Developers group can manage resources inside `rg-app-dev`.

### Auditors

- Role: Reader
- Scope: Subscription

Members of the Auditors group can read resources throughout the subscription.

This demonstrates RBAC scope and inheritance.

---

## 3. Resource Groups and Tags

Created:

`rg-app-dev`

Tags were used to organize and identify the environment.

Example:

- Environment = DEV
- Project = AzureLearning
- CostCenter = LAB

The `ManagedBy` tag was later modified using Azure CLI and Terraform.

---

## 4. Azure Policy

Assigned a built-in Azure Policy to inherit a tag from the Resource Group.

Policy:

`Inherit a tag from the resource group if missing`

This demonstrated:

- Policy definition
- Policy assignment
- Modify effect
- Remediation
- Managed Identity used by Azure Policy

---

## 5. Resource Locks

Tested resource locks using Azure Portal and Azure CLI.

### Delete Lock

Prevents deletion while still allowing modifications.

Azure CLI example:

    az lock create \
      --name cli-delete-lock \
      --lock-type CanNotDelete \
      --resource-group rg-app-dev

The lock was verified and then removed.

---

## 6. Azure CLI

Used Azure CLI to inspect and modify Azure resources.

Examples:

    az account show
    az group list
    az group show
    az role assignment list
    az group update
    az lock create
    az lock list
    az lock delete

Azure CLI was also used to add:

`ManagedBy = AzureCLI`

to the Resource Group.

---

## 7. Terraform Import

The Resource Group already existed in Azure because it was originally created manually.

Terraform configuration was created for the existing Resource Group.

The existing resource was then imported into Terraform state:

    terraform import \
      azurerm_resource_group.app_dev \
      "<RESOURCE_GROUP_ID>"

Verified with:

    terraform state list
    terraform state show azurerm_resource_group.app_dev

After import:

    terraform plan

returned:

`No changes. Your infrastructure matches the configuration.`

This confirmed that the Terraform configuration, Terraform state, and actual Azure infrastructure were aligned.

---

## 8. Terraform Change

Changed the Resource Group tag from:

`ManagedBy = AzureCLI`

to:

`ManagedBy = Terraform`

Terraform detected an in-place update:

`Plan: 0 to add, 1 to change, 0 to destroy.`

After:

    terraform apply

Azure CLI was used to verify the change:

    az group show \
      --name rg-app-dev \
      --query tags \
      -o json

A final:

    terraform plan

returned no changes.

---

## Key Takeaways

- Microsoft Entra ID manages identities.
- Azure RBAC controls who can perform actions on Azure resources.
- RBAC assignments inherit through Azure scopes.
- Azure Policy enforces governance requirements on resources.
- Tags provide metadata for organization and cost management.
- Resource Locks protect resources from accidental changes or deletion.
- Azure CLI provides command-line administration and automation.
- Terraform state maps Terraform resources to real Azure resources.
- Existing Azure resources can be brought under Terraform management using import.
- `terraform plan` compares the desired configuration with the current infrastructure.
- Terraform can manage resources that were originally created outside Terraform.
