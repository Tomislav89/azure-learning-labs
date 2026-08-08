# Microsoft Entra ID Fundamentals

## Overview

Microsoft Entra ID is Microsoft's cloud-based identity and access management (IAM) service.

It provides identity and authentication services for users, applications, and workloads that need access to Microsoft cloud services and other integrated applications.

A useful mental model is:

```text
Microsoft Entra ID
        │
        │ Authentication
        ▼
     Identity
        │
        │ Authorization / Azure RBAC
        ▼
Azure Subscription
        │
        ▼
 Resource Group
        │
        ▼
    Resources
```

---

## Identity

An identity represents a security principal that can be authenticated.

Common identity types include:

- Users
- Service Principals
- Managed Identities

Not every Azure resource is automatically an identity.

For example, a Virtual Machine is an Azure resource, but it can be assigned a Managed Identity that applications running on the VM can use to authenticate to other Azure services.

```text
Virtual Machine
      │
      └── Managed Identity
                │
                ▼
          Microsoft Entra ID
```

---

## User Account

A user account represents a person within an identity system.

Examples include:

```text
alice@contoso.com
admin@contoso.com
```

The corresponding user object is stored in the Microsoft Entra directory.

---

## Microsoft Entra Tenant

A Microsoft Entra tenant is a dedicated instance of Microsoft Entra ID associated with an organization.

It acts primarily as an identity boundary and contains identity-related objects such as:

- Users
- Groups
- Applications
- Service Principals
- Managed Identities

Example:

```text
Contoso Microsoft Entra Tenant
│
├── Users
├── Groups
├── Applications
├── Service Principals
└── Managed Identities
```

Azure resources themselves are organized through subscriptions, Resource Groups, and resources rather than being directly contained by the Entra tenant.

---

## Directory

A Microsoft Entra directory is the collection of identity objects associated with an Entra tenant.

In everyday Azure terminology, the terms **tenant** and **directory** are closely related.

For example, the Azure Portal option:

```text
Switch directory
```

allows a user to switch between Entra tenants/directories to which the user has access.

---

## Tenant vs Subscription

A Microsoft Entra tenant and an Azure subscription serve different purposes.

### Microsoft Entra Tenant

Primarily provides an identity boundary.

Contains objects such as:

```text
Users
Groups
Applications
Service Principals
Managed Identities
```

### Azure Subscription

Provides an important:

- Resource management scope
- Billing boundary
- Governance scope
- RBAC scope
- Quota boundary

Azure resources are organized under subscriptions:

```text
Subscription
    │
    ├── Resource Group
    │       ├── Virtual Machine
    │       ├── Virtual Network
    │       └── Storage Account
    │
    └── Resource Group
            └── Key Vault
```

A subscription is associated with a Microsoft Entra tenant for identity and authentication.

A useful simplified mental model is:

```text
Tenant       → Identities
Subscription → Azure resources
```

---

## Authentication vs Authorization

Authentication answers:

> Who are you?

Example:

```text
User
  │
  ▼
Microsoft Entra ID
  │
  ▼
Authenticated identity
```

Authorization answers:

> What are you allowed to do?

For Azure resources, Azure RBAC is commonly used for authorization.

Example:

```text
User
  │
  │ Azure RBAC: Reader
  ▼
Subscription
  │
  └── Can view resources
```

Authentication happens before authorization.

---

## Internal and External Identities

### Internal Identity

An internal identity represents someone associated with the organization, such as an employee.

An internal identity can be either cloud-only or synchronized from an on-premises identity system.

### External Identity

An external identity represents someone outside the organization who is given access to organizational resources.

Typical examples include:

- Consultants
- Partners
- Vendors
- Users from another organization

A common scenario is B2B collaboration.

```text
Partner Organization
        │
        │ External user
        ▼
Contoso Entra Tenant
        │
        ▼
Authorized resources
```

Internal vs external describes the identity's **relationship to the organization**.

---

## Cloud Identity

A cloud identity is created and managed directly in Microsoft Entra ID.

Example:

```text
Microsoft Entra ID
        │
        └── alice@contoso.onmicrosoft.com
```

No on-premises Active Directory identity is required as the source for the account.

---

## Hybrid Identity

A hybrid identity originates from or is connected to an on-premises identity environment and is represented in Microsoft Entra ID.

Simplified example:

```text
On-Premises Active Directory
             │
             │ Synchronization
             ▼
      Microsoft Entra ID
```

This allows organizations that already use Active Directory Domain Services to integrate their existing identities with Microsoft cloud services.

---

## Identity Classification

Internal/external and cloud/hybrid describe different characteristics.

```text
Relationship to organization:

Internal
External


Identity source/management:

Cloud
Hybrid
```

For example, an employee can be:

```text
Internal + Cloud
```

or:

```text
Internal + Hybrid
```

Therefore, **external** and **hybrid** describe different aspects of an identity.

---

## Member vs Guest

Microsoft Entra user objects commonly have a user type such as:

```text
Member
Guest
```

A **Member** typically represents a user that is part of the organization.

A **Guest** typically represents an external user invited to collaborate with the organization.

Member/Guest describes the user object's `userType`, while internal/external describes the broader relationship of the identity to the organization.

---

## Microsoft Entra ID vs Active Directory Domain Services

Microsoft Entra ID and Active Directory Domain Services are different identity platforms.

### Active Directory Domain Services

Traditional AD DS commonly uses technologies such as:

- LDAP
- Kerberos
- NTLM
- Group Policy
- Traditional domain join

### Microsoft Entra ID

Microsoft Entra ID is a cloud-native identity platform supporting modern authentication and application access technologies such as:

- OAuth 2.0
- OpenID Connect
- SAML
- Multi-Factor Authentication
- Conditional Access

Both systems manage identities, but they use different architectures and are designed for different identity scenarios.

---

## Workload Identities

Applications and automation should not normally use a person's username and password to access Azure.

For example, a CI/CD pipeline needs its own identity.

A simplified model:

```text
GitHub Actions
      │
      ▼
Workload Identity
      │
      ▼
Microsoft Entra ID
      │
      │ Azure RBAC
      ▼
Azure Resources
```

Common approaches include:

- Service Principals
- Managed Identities
- Workload identity federation

Modern CI/CD architectures should prefer short-lived or federated credentials where possible instead of storing long-lived client secrets.

---

## Key Identity Mental Model

```text
                   Microsoft Entra Tenant
                            │
          ┌─────────────────┼─────────────────┐
          │                 │                 │
        Users             Groups      Workload Identities
          │                 │                 │
          └─────────────────┴─────────────────┘
                            │
                      Authentication
                            │
                            ▼
                        Azure RBAC
                            │
                            ▼
                       Subscription
                            │
                            ▼
                       Resource Group
                            │
                            ▼
                         Resources
```

The identity and resource hierarchies are related through authentication and authorization:

```text
IDENTITY SIDE                     RESOURCE SIDE

Entra Tenant
     │
User / Group
     │
     │ Azure RBAC
     ▼
                              Subscription
                                   │
                              Resource Group
                                   │
                                Resource
```

---

## Interview Questions

1. What is Microsoft Entra ID?
2. What is an identity?
3. What is the difference between an identity and a user account?
4. What is a Microsoft Entra tenant?
5. What is the difference between a tenant and a subscription?
6. What is a Microsoft Entra directory?
7. What is the difference between authentication and authorization?
8. What is the difference between an internal and external identity?
9. What is the difference between a cloud identity and a hybrid identity?
10. Can an internal employee have a hybrid identity?
11. Can a Virtual Machine have an identity?
12. What is the difference between Microsoft Entra ID and Active Directory Domain Services?
13. Why should a CI/CD pipeline not use a personal user account to deploy Azure infrastructure?

---

## Key Takeaways

- Microsoft Entra ID is Microsoft's cloud identity and access management service.
- An Entra tenant is primarily an identity boundary.
- An Azure subscription is primarily a resource management, billing, and governance boundary.
- Authentication determines who an identity is.
- Authorization determines what that identity is allowed to do.
- Internal/external describes the relationship to the organization.
- Cloud/hybrid describes how or where an identity is managed.
- Azure resources are not automatically identities, but supported resources can use Managed Identities.
- Microsoft Entra ID and Active Directory Domain Services are different identity platforms.
- Automation should use workload identities instead of personal user credentials.
