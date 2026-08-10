# Azure Role-Based Access Control (RBAC)

## Overview

Azure Role-Based Access Control (Azure RBAC) is Azure's authorization system for managing access to Azure resources.

Microsoft Entra ID authenticates an identity, while Azure RBAC determines what that identity is authorized to do with Azure resources.

A simplified model is:

```text
Microsoft Entra ID
        │
        │ Authentication
        ▼
Security Principal
        │
        │ Authorization
        ▼
    Azure RBAC
        │
        ▼
 Azure Resources
```

Authentication answers:

```text
Who are you?
```

Authorization answers:

```text
What are you allowed to do?
```

---

## RBAC Role Assignment

An Azure RBAC role assignment consists of three fundamental elements:

```text
Security Principal + Role Definition + Scope
```

A useful mental model is:

```text
WHO + WHAT + WHERE
```

Example:

```text
grp-developers + Contributor + rg-app-dev
```

This means:

```text
WHO?
grp-developers

WHAT?
Contributor

WHERE?
rg-app-dev
```

Together, these elements create a **Role Assignment**.

---

## Security Principal

A Security Principal represents the identity that receives access.

Common security principals include:

```text
Security Principal
│
├── User
├── Group
├── Service Principal
└── Managed Identity
```

### User

A role can be assigned directly to an individual user.

```text
Alice
  │
  │ Reader
  ▼
Subscription
```

For larger environments, group-based access is generally easier to manage.

### Group

Users can be placed into Microsoft Entra Security Groups and RBAC roles assigned to the group.

```text
Alice ─┐
Bob ───┼──→ grp-developers
Sarah ─┘          │
                  │ Contributor
                  ▼
             rg-app-dev
```

This allows access to be managed through group membership.

### Service Principal

Applications and automation can use Service Principals instead of human identities.

Example:

```text
Automation / Application
          │
          ▼
   Service Principal
          │
          │ Azure RBAC
          ▼
    Azure Resources
```

### Managed Identity

Supported Azure resources can use Managed Identities to authenticate to other Azure services.

Example:

```text
Virtual Machine
      │
      ▼
Managed Identity
      │
      │ RBAC
      ▼
   Key Vault
```

Service Principals and Managed Identities are covered in more detail later in the Identity and Governance module.

---

## Role Definition

A Role Definition describes the permissions associated with a role.

It answers:

```text
WHAT is the security principal allowed to do?
```

For example:

```text
Reader
  │
  └── View resources
```

or:

```text
Contributor
  │
  ├── Read
  ├── Create
  ├── Update
  └── Delete
```

Azure provides many built-in role definitions.

Custom role definitions can also be created when built-in roles do not meet the required access model.

---

## Built-in Azure Roles

Azure provides many built-in RBAC roles.

Four important roles to understand are:

- Reader
- Contributor
- Owner
- User Access Administrator

---

## Reader

The Reader role allows a security principal to view Azure resources.

```text
Reader
  │
  └── View resources
```

It does not allow the principal to modify those resources.

Example:

```text
grp-auditors
      │
      │ Reader
      ▼
Production Subscription
```

This is useful for users who need visibility without resource modification permissions.

---

## Contributor

The Contributor role allows management of Azure resources.

Conceptually:

```text
Contributor
│
├── Read
├── Create
├── Update
└── Delete
```

However, Contributor does not provide permission to grant Azure RBAC access to other principals.

Example:

```text
grp-developers
      │
      │ Contributor
      ▼
   rg-app-dev
```

Developers can manage resources within the assigned scope without receiving general permission to manage Azure RBAC access.

---

## Owner

The Owner role provides broad resource management permissions and the ability to assign Azure RBAC roles.

A simplified comparison is:

```text
Owner
  │
  ├── Manage resources
  └── Manage Azure RBAC access
```

Conceptually:

```text
Owner
≈
Contributor capabilities
+
ability to manage access
```

Because Owner is highly privileged, it should be assigned only when required.

---

## User Access Administrator

User Access Administrator focuses on managing access to Azure resources.

A useful simplified comparison is:

```text
Contributor
    │
    └── Manage resources


User Access Administrator
    │
    └── Manage access


Owner
    │
    ├── Manage resources
    └── Manage access
```

This separation is useful when access administration should be delegated without giving general resource-management permissions.

---

## Scope

Scope determines where a role assignment applies.

The main Azure RBAC scopes follow the Azure resource hierarchy:

```text
Management Group
       │
       ▼
Subscription
       │
       ▼
Resource Group
       │
       ▼
Resource
```

A role can therefore be assigned at different levels.

Example:

```text
grp-developers
+
Contributor
+
DEV Subscription
```

or more narrowly:

```text
grp-developers
+
Contributor
+
rg-app-dev
```

The appropriate scope should be selected based on the access requirement.

---

## RBAC Inheritance

Role assignments at higher scopes are inherited by lower scopes.

Example:

```text
DEV Subscription
│
│ grp-developers → Contributor
│
├── rg-app-dev
│   ├── Virtual Machine
│   └── Storage Account
│
└── rg-network-dev
    └── Virtual Network
```

The Contributor assignment at Subscription scope applies to resources beneath that subscription.

The inheritance hierarchy is:

```text
Management Group
       │
       ▼
Subscription
       │
       ▼
Resource Group
       │
       ▼
Resource
```

This allows administrators to manage access efficiently without creating individual role assignments on every resource.

---

## Principle of Least Privilege

Access should be granted using the minimum permissions required to perform the required task.

The role should also be assigned at the smallest practical scope.

For example, if developers only need to manage resources inside:

```text
rg-app-dev
```

prefer:

```text
grp-developers
      │
      │ Contributor
      ▼
   rg-app-dev
```

instead of:

```text
grp-developers
      │
      │ Contributor
      ▼
Entire Subscription
```

The goal is not necessarily to use the smallest technically possible scope for every assignment.

The goal is to use the smallest **practical** scope that satisfies the requirement while keeping access management maintainable.

---

## Effective Permissions

A security principal can receive permissions through multiple role assignments.

These assignments can come from:

- Direct role assignments
- Group memberships
- Inherited assignments

Example:

```text
Alice
│
├── Reader
│      │
│      ▼
│   Subscription
│
└── Member of grp-developers
           │
           │ Contributor
           ▼
       rg-app-dev
```

Inside `rg-app-dev`, Alice receives permissions from both applicable assignments.

Azure RBAC allow permissions are generally cumulative.

Conceptually:

```text
Reader
+
Contributor
=
Effective permissions include Contributor capabilities
```

A less privileged role does not normally remove permissions granted by another applicable role assignment.

When troubleshooting unexpected access, check:

```text
Direct Assignments
        +
Group Memberships
        +
Inherited Assignments
        ↓
Effective Access
```

---

## Role Definition vs Role Assignment

These concepts serve different purposes.

### Role Definition

Defines:

```text
What does this role allow?
```

Example:

```text
Contributor
│
└── Defines Contributor permissions
```

### Role Assignment

Defines:

```text
Who receives which role at which scope?
```

Example:

```text
grp-developers
       +
Contributor
       +
rg-app-dev
```

Therefore:

```text
ROLE DEFINITION
"What can Contributor do?"


ROLE ASSIGNMENT
"Give Contributor to grp-developers on rg-app-dev."
```

---

## Built-in Roles vs Custom Roles

Azure provides many built-in roles for common access requirements.

Examples include:

```text
Reader
Contributor
Owner
User Access Administrator
Network Contributor
Virtual Machine Contributor
Storage Blob Data Reader
```

Built-in roles should generally be preferred when they satisfy the requirement.

A Custom Role can be created when existing built-in roles provide either too much or too little access.

Example requirement:

```text
Operations team must:

- Read VM configuration
- Restart VMs
- Not delete VMs
```

If an appropriate built-in role does not meet the requirement, a Custom Role can define the required permissions.

A useful approach is:

```text
Check built-in roles
        │
        ├── Suitable → Use built-in role
        │
        └── Not suitable → Consider Custom Role
```

Custom roles introduce additional maintenance and should be created when there is a clear requirement.

---

## Control Plane and Data Plane Access

Azure authorization can apply to different types of operations.

A useful example is Azure Storage.

```text
Storage Account
│
├── Control Plane
│   │
│   └── Manage or view the Azure resource
│
└── Data Plane
    │
    └── Access the actual stored data
```

For example, having access to view a Storage Account resource does not necessarily mean that the identity can read the blobs stored inside it.

Different roles can provide different types of access.

Example:

```text
Reader
```

can provide visibility into resource configuration at the management plane, while:

```text
Storage Blob Data Reader
```

is designed to provide read access to blob data.

This distinction becomes especially important when working with:

- Azure Storage
- Key Vault
- Databases
- Other Azure data services

---

## Security Groups vs Management Groups

Microsoft Entra Security Groups and Azure Management Groups serve completely different purposes.

### Microsoft Entra Security Group

Contains identities.

```text
grp-developers
│
├── Alice
├── Bob
└── Sarah
```

Used for:

```text
Identity and access management
```

### Azure Management Group

Organizes Azure subscriptions.

```text
Root Management Group
│
└── IT
    │
    ├── Development
    │   └── DEV Subscription
    │
    └── Production
        └── PROD Subscription
```

Used for:

```text
Azure resource governance hierarchy
```

A useful distinction is:

```text
Security Group
      │
      ▼
    USERS


Management Group
      │
      ▼
SUBSCRIPTIONS
```

The names of Management Groups are organizational choices.

For example:

```text
IT
Finance
Development
Production
Platform
```

A Management Group named `Development` does not contain developer user accounts.

Developer identities would typically belong to a Microsoft Entra Security Group such as:

```text
grp-developers
```

Azure RBAC then connects the identity side with the Azure resource hierarchy.

```text
Microsoft Entra ID                    Azure

Alice ─┐
Bob ───┼→ grp-developers
Sarah ─┘        │
                │ RBAC
                ▼
          DEV Subscription
```

---

## Enterprise Access Example

Consider an organization with:

- 50 developers
- 5 database administrators
- 3 auditors
- DEV Subscription
- PROD Subscription

Requirements:

```text
Developers:
Contributor → DEV

Database Administrators:
Contributor → rg-database-prod

Auditors:
Reader → DEV and PROD
```

Create three Microsoft Entra Security Groups:

```text
Microsoft Entra ID
│
├── grp-developers
├── grp-db-admins
└── grp-auditors
```

Configure RBAC assignments:

```text
grp-developers
      │
      │ Contributor
      ▼
DEV Subscription
```

```text
grp-db-admins
      │
      │ Contributor
      ▼
rg-database-prod
```

```text
grp-auditors
      │
      ├── Reader → DEV Subscription
      │
      └── Reader → PROD Subscription
```

The complete access model can be represented as:

```text
SECURITY PRINCIPAL          ROLE             SCOPE

grp-developers       →   Contributor   →   DEV Subscription

grp-db-admins        →   Contributor   →   rg-database-prod

grp-auditors         →   Reader        →   DEV Subscription
grp-auditors         →   Reader        →   PROD Subscription
```

This follows the model:

```text
WHO → WHAT → WHERE
```

---

## Azure Portal

Azure RBAC is managed through:

```text
Azure Resource
      │
      ▼
Access control (IAM)
```

For example:

```text
Resource Group
      │
      ▼
Access control (IAM)
      │
      ▼
Add role assignment
      │
      ├── Select Role
      │
      ├── Select Member / Identity
      │
      └── Review + Assign
```

The Azure resource from which `Access control (IAM)` is opened determines the scope of the assignment.

For example:

```text
rg-app-dev
    │
    ▼
Access control (IAM)
    │
    ▼
Contributor → grp-developers
```

results in:

```text
WHO:
grp-developers

WHAT:
Contributor

WHERE:
rg-app-dev
```

---

## Terraform Preview

Azure RBAC assignments can be managed with Terraform.

Example:

```hcl
resource "azurerm_role_assignment" "developers" {
  scope                = azurerm_resource_group.app_dev.id
  role_definition_name = "Contributor"
  principal_id         = var.developers_group_object_id
}
```

The same RBAC model is visible in the Terraform configuration:

```text
principal_id
    │
    └── WHO


role_definition_name
    │
    └── WHAT


scope
    │
    └── WHERE
```

This will be implemented practically later in the roadmap.

---

## Interview Questions

1. What is Azure RBAC?
2. What is the difference between authentication and authorization?
3. What are the three main components of an Azure RBAC role assignment?
4. What is a Security Principal?
5. What types of Security Principals can receive Azure RBAC roles?
6. What is a Role Definition?
7. What is a Role Assignment?
8. What is the difference between Reader, Contributor, and Owner?
9. What is the difference between Contributor and User Access Administrator?
10. What is an Azure RBAC scope?
11. At which scopes can Azure RBAC roles be assigned?
12. How does RBAC inheritance work?
13. What is the principle of least privilege?
14. Why would you assign Contributor at Resource Group scope instead of Subscription scope?
15. How are effective permissions calculated when a user has multiple applicable role assignments?
16. When should you consider creating a Custom Role?
17. What is the difference between control-plane and data-plane access?
18. What is the difference between a Microsoft Entra Security Group and an Azure Management Group?
19. How would you give developers Contributor access to DEV without giving them access to PROD?
20. Why is group-based RBAC generally preferable to assigning roles individually to many users?

---

## Key Takeaways

- Azure RBAC controls authorization to Azure resources.
- Microsoft Entra ID authenticates identities; Azure RBAC determines what they can do.
- A Role Assignment consists of Security Principal + Role Definition + Scope.
- The simplified RBAC model is WHO + WHAT + WHERE.
- Security Principals include users, groups, Service Principals, and Managed Identities.
- Reader provides read-only resource access.
- Contributor manages resources but does not grant general Azure RBAC role-assignment capability.
- Owner can manage resources and Azure RBAC access.
- User Access Administrator focuses on access management.
- RBAC assignments are inherited from higher Azure scopes to lower scopes.
- Apply the principle of least privilege and use the smallest practical scope.
- Effective access can result from direct, group-based, and inherited role assignments.
- Built-in roles should generally be preferred over Custom Roles when they satisfy the requirement.
- Control-plane resource access and data-plane access are different concepts.
- Entra Security Groups contain identities; Azure Management Groups organize subscriptions.
- Group-based RBAC provides a scalable enterprise access-management model.
