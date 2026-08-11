# Microsoft Entra Roles

## Overview

Microsoft Entra roles are used to delegate administrative permissions within Microsoft Entra ID.

They control who can perform identity and directory administration tasks such as:

- Managing users
- Managing groups
- Managing applications
- Resetting passwords
- Managing identity-related configuration

Microsoft Entra roles are different from Azure RBAC roles.

A useful mental model is:

```text
Microsoft Entra Roles
        ↓
Identity / Directory Administration


Azure RBAC Roles
        ↓
Azure Resource Access
```

---

## Microsoft Entra Roles vs Azure RBAC

Microsoft Entra roles and Azure RBAC roles are two different authorization systems.

### Microsoft Entra Roles

Microsoft Entra roles control administrative permissions inside Microsoft Entra ID.

Examples of objects and capabilities they can manage include:

```text
Microsoft Entra ID
│
├── Users
├── Groups
├── Applications
└── Identity configuration
```

### Azure RBAC

Azure RBAC controls access to Azure resources.

Examples include:

```text
Azure
│
├── Management Groups
├── Subscriptions
├── Resource Groups
│
├── Virtual Machines
├── Virtual Networks
├── Storage Accounts
└── Other Azure resources
```

The fundamental distinction is:

```text
Entra Role
→ administer identity and directory capabilities

Azure RBAC Role
→ access and manage Azure resources
```

---

## Authentication and Authorization

Microsoft Entra ID authenticates identities.

```text
User
 ↓
Microsoft Entra ID
 ↓
Authentication
 ↓
Identity verified
```

After authentication, authorization determines what the identity is allowed to do.

Two important authorization systems are:

```text
                    AUTHORIZATION
                         │
              ┌──────────┴──────────┐
              │                     │
              ▼                     ▼
        Entra Roles             Azure RBAC
              │                     │
              ▼                     ▼
      Entra administration     Azure resources
```

---

## Global Administrator

Global Administrator is a highly privileged Microsoft Entra administrative role.

It provides broad administrative capabilities across Microsoft Entra ID.

Conceptually:

```text
Global Administrator
        ↓
Broad Entra administrative access
```

Because this role is highly privileged, it should be assigned only when necessary.

Enterprise principle:

```text
Do not use Global Administrator for routine administration
when a less privileged role can perform the required task.
```

This follows the principle of least privilege.

---

## User Administrator

User Administrator provides administrative capabilities related to users and supported group-management operations.

Typical responsibilities can include:

```text
User Administrator
       │
       ├── Manage users
       ├── Create users
       ├── Update users
       └── Perform supported password and group operations
```

The exact operations available depend on the target identity, role hierarchy, and Microsoft Entra configuration.

A User Administrator does not automatically receive permission to manage Azure infrastructure resources.

For example:

```text
Alice
  │
  └── User Administrator
          ↓
    Microsoft Entra ID
```

does not automatically mean:

```text
Alice
  │
  └── Can modify Azure VM
```

Azure resource access requires the appropriate Azure RBAC assignment.

---

## Groups Administrator

Groups Administrator provides administrative capabilities for Microsoft Entra groups.

Typical group-management tasks include:

- Creating groups
- Updating groups
- Deleting supported groups
- Managing group membership
- Managing group owners
- Managing supported group settings

Example:

```text
Groups Administrator
        │
        ▼
grp-developers
│
├── Alice
├── Bob
└── Sarah
```

Group administration determines who belongs to the group.

This is different from assigning Azure RBAC permissions to the group.

---

## Group Management and Azure RBAC

Consider the following Security Group:

```text
grp-developers
│
├── Alice
├── Bob
└── Sarah
```

The group already has:

```text
grp-developers
       │
       │ Contributor
       ▼
   rg-app-dev
```

Someone authorized to add another user to `grp-developers` can indirectly give that user the access already granted to the group.

For example:

```text
John
 │
 │ Added to group
 ▼
grp-developers
       │
       │ Contributor
       ▼
   rg-app-dev
```

John can then receive the group's applicable access.

However, permission to manage group membership does not automatically mean that the administrator can create a new Azure RBAC role assignment.

These are separate administrative capabilities:

```text
Entra Group Management
        │
        ▼
WHO belongs to the group


Azure RBAC
        │
        ▼
WHAT the group can access
and WHERE
```

For this reason, management of highly privileged groups is security-sensitive.

---

## Application Administrator

Application Administrator provides administrative capabilities for Microsoft Entra applications and related application-management scenarios.

Conceptually:

```text
Application Administrator
          │
          ▼
Microsoft Entra Applications
```

Applications, App Registrations, Service Principals, and workload identities are covered separately.

---

## Security Reader

Security Reader provides read-only access to supported security-related information.

Conceptually:

```text
Security Reader
       │
       ▼
View security information
```

This is useful when someone needs security visibility without broad administrative permissions.

---

## Global Administrator vs Azure RBAC Owner

Global Administrator and Azure RBAC Owner are not the same role.

They belong to different authorization systems.

### Global Administrator

```text
Global Administrator
        │
        ▼
Microsoft Entra administration
```

### Azure RBAC Owner

```text
Owner
  │
  ▼
Azure Scope
  │
  ├── Manage resources
  └── Manage Azure RBAC access
```

An Owner role always applies at an Azure scope.

For example:

```text
Alice
  │
  │ Owner
  ▼
DEV Subscription
```

or:

```text
Alice
  │
  │ Owner
  ▼
rg-app-dev
```

A useful distinction is:

```text
Global Administrator
→ highly privileged Entra role


Owner
→ highly privileged Azure RBAC role
  at an assigned Azure scope
```

The two systems should not be treated as interchangeable.

---

## Contributor Does Not Make Someone an Entra Administrator

Consider:

```text
Alice
  │
  │ Contributor
  ▼
Azure Subscription
```

Alice can manage Azure resources according to the permissions of the Contributor role.

However, Contributor does not automatically allow Alice to:

```text
Create Entra users
Delete Entra users
Manage Entra groups
Administer Entra applications
```

Those operations require appropriate Microsoft Entra administrative permissions.

---

## Entra Administrator Does Not Automatically Manage Azure Resources

Consider:

```text
Bob
 │
 │ User Administrator
 ▼
Microsoft Entra ID
```

This does not automatically allow Bob to:

```text
Delete a VM
Create a VNet
Modify a Storage Account
Delete an Azure Resource Group
```

Those operations require appropriate Azure RBAC permissions.

---

## One Identity Can Have Both Types of Access

A user can have both Microsoft Entra administrative permissions and Azure RBAC permissions.

Example requirement:

```text
Alice must:

1. Administer Entra users
2. Manage resources in rg-app-dev
```

The access model could conceptually be:

```text
Alice
│
├── Microsoft Entra
│      │
│      └── User Administrator
│
└── Azure
       │
       └── Contributor → rg-app-dev
```

These are two separate assignments serving different purposes.

---

## Least Privilege

The principle of least privilege applies to both Microsoft Entra roles and Azure RBAC.

The process should be:

```text
Required Task
      ↓
Determine required permissions
      ↓
Choose least-privileged suitable role
      ↓
Choose appropriate target / scope
      ↓
Assign access
```

For example, if a helpdesk employee only requires limited identity administration capabilities, assigning Global Administrator would provide unnecessary privileges.

Instead:

```text
Helpdesk Requirement
        ↓
Find appropriate limited Entra role
        ↓
Assign only required privileges
```

The same principle applies to Azure RBAC.

If an engineer only needs to manage:

```text
rg-app-dev
```

prefer:

```text
Contributor
     ↓
rg-app-dev
```

instead of unnecessarily assigning:

```text
Contributor
     ↓
Entire Subscription
```

---

## Microsoft Entra Roles and Scope

Microsoft Entra administrative roles operate within the identity and directory administration model.

They should not be confused with the Azure resource hierarchy used by Azure RBAC.

Azure RBAC uses scopes such as:

```text
Management Group
       ↓
Subscription
       ↓
Resource Group
       ↓
Resource
```

Therefore:

```text
Contributor → rg-app-dev
```

is an Azure RBAC assignment.

By contrast:

```text
User Administrator
```

is a Microsoft Entra administrative role.

The two authorization models solve different problems.

---

## Enterprise Access Example

Consider three teams:

```text
Identity Administrators
Developers
Auditors
```

Requirements:

```text
Identity Administrators
→ manage users and groups

Developers
→ manage Azure resources in rg-app-dev

Auditors
→ read Azure resources across PROD
```

Create Microsoft Entra Security Groups:

```text
Microsoft Entra ID
│
├── grp-identity-admins
├── grp-developers
└── grp-auditors
```

Then assign the appropriate roles.

### Identity Administrators

```text
grp-identity-admins
        │
        │ Appropriate Entra administrative role(s)
        ▼
Microsoft Entra ID
```

The exact role should be selected according to the required administrative tasks.

### Developers

```text
grp-developers
       │
       │ Contributor
       ▼
   rg-app-dev
```

This is an Azure RBAC assignment.

### Auditors

```text
grp-auditors
       │
       │ Reader
       ▼
PROD Subscription
```

This is also an Azure RBAC assignment.

The complete model is:

```text
GROUP                   ROLE                     TARGET / SCOPE

grp-identity-admins  →  Entra administrative  → Microsoft Entra ID

grp-developers       →  Contributor           → rg-app-dev

grp-auditors         →  Reader                → PROD Subscription
```

---

## Security Groups and Authorization

Microsoft Entra Security Groups can be used to simplify access administration.

For example:

```text
Users
  │
  ▼
Security Group
  │
  ├──────── Entra Role ────────→ Entra administration
  │
  └──────── Azure RBAC ────────→ Azure resources
```

The important distinction is not the group itself.

The important distinction is **which authorization system and role are being used**.

---

## Mental Model

A useful overall architecture is:

```text
                  MICROSOFT ENTRA TENANT
                           │
             ┌─────────────┴─────────────┐
             │                           │
             ▼                           ▼
   IDENTITY ADMINISTRATION         AZURE RESOURCE ACCESS
             │                           │
        Entra Roles                  Azure RBAC
             │                           │
             ▼                           ▼
           Users                  Management Group
           Groups                       │
       Applications                Subscription
                                         │
                                    Resource Group
                                         │
                                      Resource
```

The shortest version to remember is:

```text
Entra Roles
→ Identity / Directory Administration

Azure RBAC
→ Azure Resource Authorization
```

---

## Interview Questions

1. What are Microsoft Entra administrative roles?
2. What is the difference between Microsoft Entra roles and Azure RBAC roles?
3. What does the Global Administrator role provide?
4. Why should Global Administrator assignments be limited?
5. What is the purpose of User Administrator?
6. What is the purpose of Groups Administrator?
7. What is the difference between managing an Entra Security Group and managing its Azure RBAC assignments?
8. Why is permission to modify membership of a privileged group security-sensitive?
9. What is the difference between Global Administrator and Azure RBAC Owner?
10. Does Contributor on an Azure subscription allow a user to create Entra users?
11. Does User Administrator automatically allow a user to modify Azure VMs?
12. Can one identity have both an Entra administrative role and an Azure RBAC role?
13. How does the principle of least privilege apply to Entra administrative roles?
14. How would you provide someone with user administration permissions and Contributor access only to `rg-app-dev`?
15. Which authorization system would you use to allow someone to manage Azure resources?
16. Which authorization system would you use to allow someone to manage Microsoft Entra users?

---

## Key Takeaways

- Microsoft Entra roles provide administrative permissions within Microsoft Entra ID.
- Azure RBAC controls authorization to Azure resources.
- Entra roles and Azure RBAC roles are separate authorization systems.
- Global Administrator is a highly privileged Microsoft Entra role.
- User Administrator provides supported user-administration capabilities.
- Groups Administrator provides supported group-administration capabilities.
- Application Administrator provides application-administration capabilities.
- Security Reader provides read-only access to supported security information.
- Global Administrator and Azure RBAC Owner are not equivalent.
- Azure RBAC Owner applies at an Azure resource scope.
- Contributor does not automatically provide Microsoft Entra administrative permissions.
- An Entra administrative role does not automatically provide Azure resource permissions.
- One identity can receive both Entra roles and Azure RBAC roles when required.
- Group membership management can indirectly grant access when a group already has privileged role assignments.
- Always apply the principle of least privilege.
