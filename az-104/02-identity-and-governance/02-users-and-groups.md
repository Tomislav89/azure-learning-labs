# Microsoft Entra Users and Groups

## Overview

Microsoft Entra ID stores users, groups, applications, and workload identities inside an organization's directory.

Users and groups are fundamental building blocks for identity and access management.

Instead of assigning permissions directly to many individual users, enterprise environments commonly assign permissions to groups and manage access through group membership.

A useful model is:

```text
User
  ↓
Security Group
  ↓
Azure RBAC Role
  ↓
Azure Scope
  ↓
Azure Resources
```

---

## Microsoft Entra User Object

A Microsoft Entra user object represents a user inside the Entra directory.

A user object contains identity-related properties such as:

- Display name
- User Principal Name (UPN)
- Object ID
- User type
- Account status
- Group memberships
- Assigned roles

Example:

```text
Display Name: Alice Smith
UPN: alice@contoso.com
Object ID: 12345678-abcd-...
User Type: Member
```

---

## User Principal Name

The User Principal Name, or UPN, is commonly used as the user's sign-in name.

Example:

```text
alice@contoso.com
```

A UPN often looks like an email address, but it is conceptually a sign-in identifier and does not have to be the same as the user's email address.

---

## Object ID

Every Microsoft Entra object has a unique Object ID.

Examples of objects that have Object IDs include:

- Users
- Groups
- Service Principals
- Managed Identities

Object IDs are especially useful in:

- Azure CLI
- Terraform
- Microsoft Graph
- Automation
- RBAC assignments

Display names are designed for humans and may not be unique, while Object IDs uniquely identify directory objects.

---

## Member and Guest Users

Microsoft Entra user objects commonly have a user type of:

```text
Member
Guest
```

### Member

A Member typically represents a user who belongs to the organization.

For example:

```text
Contoso
  │
  └── Alice
      User Type: Member
```

A Member can be:

- Cloud-only
- Hybrid / synchronized

### Guest

A Guest typically represents an external collaborator.

Common examples include:

- Consultants
- Partners
- Vendors
- Contractors

Example:

```text
Partner Company
      │
      │ Consultant
      ▼
Contoso Entra Tenant
      │
      └── User Type: Guest
```

The Guest user has an object inside the destination tenant so that access can be assigned and managed.

---

## Why Use Groups?

Groups simplify identity and access management.

Without groups:

```text
Alice  ──→ Contributor
Bob    ──→ Contributor
Sarah  ──→ Contributor
John   ──→ Contributor
```

With a group:

```text
Alice ─┐
Bob ───┤
Sarah ─┼──→ grp-azure-developers
John ──┘
               │
               │ Contributor
               ▼
          Azure Resource Group
```

If a new developer joins:

```text
New Developer
      │
      ▼
Add to group
      │
      ▼
Receives group-based access
```

This approach is easier to manage and scales better than individual role assignments.

---

## Security Groups

Security Groups are commonly used to organize identities for access management.

Example:

```text
grp-azure-network-contributors
```

Members:

```text
grp-azure-network-contributors
│
├── Alice
├── Bob
└── Sarah
```

An Azure RBAC role can then be assigned to the group:

```text
grp-azure-network-contributors
              │
              │ Network Contributor
              ▼
        Azure Subscription
```

The members receive access through the group assignment.

---

## Microsoft 365 Groups

Microsoft 365 Groups are primarily designed for Microsoft 365 collaboration scenarios.

They can provide shared resources for users working together across Microsoft 365 services.

For Azure infrastructure administration, Security Groups are generally more relevant than Microsoft 365 Groups.

---

## Group Membership Types

Microsoft Entra groups can use different membership models.

Common membership types include:

```text
Assigned
Dynamic User
Dynamic Device
```

---

## Assigned Membership

With Assigned membership, users are explicitly added or removed by an administrator or authorized group owner.

Example:

```text
Developers
│
├── Alice
├── Bob
└── Sarah
```

When a new developer joins:

```text
Administrator
      │
      ▼
Add user to Developers group
```

This model is simple but requires ongoing administration.

---

## Dynamic User Membership

Dynamic User groups calculate membership automatically based on user attributes.

Example attribute:

```text
department = Engineering
```

A membership rule can conceptually represent:

```text
If department == Engineering
    → User belongs to Engineering group
```

The resulting model is:

```text
User Attribute
department = Engineering
        │
        ▼
Dynamic Membership Rule
        │
        ▼
Engineering Security Group
        │
        ▼
Azure RBAC
        │
        ▼
Azure Resources
```

This reduces manual administration when identity attributes are maintained correctly.

Dynamic membership availability depends on Microsoft Entra licensing.

---

## Dynamic Device Membership

Dynamic membership can also be based on device attributes.

Example:

```text
Device Attributes
      │
      ▼
Dynamic Membership Rule
      │
      ▼
Device Group
```

This is especially useful in endpoint management scenarios.

---

## Group Owner vs Group Member

### Group Member

A member belongs to the group.

Example:

```text
Developers
│
├── Alice
├── Bob
└── Sarah
```

### Group Owner

A group owner can manage supported aspects of the group, such as group membership, depending on configuration and permissions.

Example:

```text
Developers Group

Owner:
Tom

Members:
Alice
Bob
Sarah
```

A Microsoft Entra Group Owner is different from the Azure RBAC Owner role.

```text
Group Owner
    │
    └── Manages the Entra group


Azure RBAC Owner
    │
    └── Manages Azure resources and can assign RBAC roles
        at the assigned Azure scope
```

---

## Security Groups vs Azure Management Groups

These are different concepts.

### Microsoft Entra Security Group

Contains identities.

```text
Security Group
│
├── Alice
├── Bob
└── Sarah
```

Main purpose:

```text
Organize identities for access management
```

### Azure Management Group

Contains or organizes Azure subscriptions within the Azure governance hierarchy.

```text
Management Group
│
├── Development Subscription
├── Test Subscription
└── Production Subscription
```

Main purpose:

```text
Organize subscriptions for governance and access management
```

A useful distinction is:

```text
Security Group   → Identities
Management Group → Subscriptions
```

---

## Group-Based Azure Access

A scalable Azure access model commonly follows:

```text
USER
  ↓
GROUP
  ↓
ROLE
  ↓
SCOPE
```

For example:

```text
Developers
     │
     │ Contributor
     ▼
rg-app-dev
```

The role assignment contains three important elements:

```text
Security Principal + Role + Scope
```

or more simply:

```text
WHO + WHAT + WHERE
```

Example:

```text
WHO:
grp-azure-developers

WHAT:
Contributor

WHERE:
rg-app-dev
```

Azure RBAC is covered in detail in the next lesson.

---

## Example: Development, Test, and Production

Requirement:

```text
Developers:

DEV  → Contributor
TEST → Reader
PROD → No general access
```

Create a Security Group:

```text
grp-azure-developers
│
├── Alice
├── Bob
├── Sarah
└── John
```

Then configure Azure RBAC:

```text
grp-azure-developers
        │
        ├── Contributor
        │       │
        │       ▼
        │   rg-app-dev
        │
        ├── Reader
        │       │
        │       ▼
        │   rg-app-test
        │
        └── No assignment
                │
                ▼
            rg-app-prod
```

This keeps identity membership separate from Azure resource permissions.

---

## Bulk User Operations

Creating hundreds of users manually through the Azure Portal is inefficient.

Bulk and automated approaches can include:

- CSV-based operations
- Microsoft Graph
- PowerShell
- Automation workflows
- Identity lifecycle systems

Example:

```text
Identity Source
      │
      ▼
Automation
      │
      ▼
Microsoft Entra ID
      │
      ├── Users
      └── Groups
```

Automation becomes increasingly important as an organization grows.

---

## User Offboarding

Deleting an account immediately is not always the best first step when an employee leaves an organization.

A typical offboarding process can include:

```text
Employee leaves
      │
      ▼
Block sign-in
      │
      ▼
Revoke active access
      │
      ▼
Remove privileged permissions
      │
      ▼
Review group memberships
      │
      ▼
Transfer required ownership or business data
      │
      ▼
Delete account according to organizational policy
```

Disabling access first allows the organization to immediately prevent sign-in while completing required lifecycle and data management activities.

---

## Enterprise Access Pattern

For Azure environments, access should generally be managed through groups rather than large numbers of individual assignments.

Example naming:

```text
grp-azure-platform-admins
grp-azure-network-contributors
grp-azure-security-readers
grp-azure-dev-contributors
```

A typical model is:

```text
Users
  │
  ▼
Microsoft Entra Security Group
  │
  ▼
Azure RBAC Role
  │
  ▼
Azure Scope
```

This improves:

- Scalability
- Access reviews
- User onboarding
- User offboarding
- Consistency
- Automation

---

## Interview Questions

1. What is a Microsoft Entra user object?
2. What is a User Principal Name?
3. Is a UPN always the same as an email address?
4. What is an Object ID?
5. What is the difference between a Member and a Guest user?
6. Why should Azure permissions generally be assigned to groups rather than individual users?
7. What is the primary purpose of an Entra Security Group?
8. What is the difference between Assigned and Dynamic group membership?
9. How would you automatically group all users whose department is Engineering?
10. What is the difference between a Group Owner and the Azure RBAC Owner role?
11. What is the difference between an Entra Security Group and an Azure Management Group?
12. How would you onboard hundreds of users efficiently?
13. Why might an organization disable a departing user's account before deleting it?
14. How would you give developers Contributor access to development, Reader access to testing, and no general access to production?

---

## Key Takeaways

- A Microsoft Entra user object represents a user inside the directory.
- A UPN is commonly used as the user's sign-in name.
- Object IDs uniquely identify Entra objects.
- Members typically belong to the organization, while Guests commonly represent external collaborators.
- Security Groups simplify access management.
- Group-based RBAC scales better than individual user assignments.
- Assigned membership is manually managed.
- Dynamic membership is calculated from identity attributes and rules.
- Group Owner and Azure RBAC Owner are different concepts.
- Security Groups contain identities, while Management Groups organize Azure subscriptions.
- Bulk operations and automation are preferred for large-scale identity administration.
- Azure access can be modeled as: User → Group → Role → Scope.
