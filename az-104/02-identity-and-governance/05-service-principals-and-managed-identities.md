# Service Principals and Managed Identities

## Overview

Microsoft Entra ID supports identities for both humans and workloads.

A simple mental model is:

```text
Microsoft Entra ID
│
├── Human Identities
│   └── Users
│
└── Workload Identities
    ├── Service Principals
    └── Managed Identities
```

Applications and automation should not normally depend on an employee's personal account.

Instead, workloads should use their own identity.

---

# Security Principal and RBAC

Users, groups, Service Principals, and Managed Identities can act as security principals.

```text
Security Principal
│
├── User
├── Group
├── Service Principal
└── Managed Identity
```

The identity answers:

```text
WHO?
```

Azure RBAC determines:

```text
WHAT can it do?

WHERE can it do it?
```

Example:

```text
Service Principal
        │
        │ Contributor
        ▼
    rg-app-dev
```

Therefore:

```text
Service Principal = Identity

RBAC = Authorization
```

A Service Principal does not automatically have access to Azure resources.

It must receive the required permissions.

---

# Service Principal

A Service Principal represents an application or workload within a Microsoft Entra tenant.

A useful simplified comparison is:

```text
Person
  ↓
User Identity


Application / Automation
  ↓
Service Principal
```

For example, Terraform automation running outside Azure may use a workload identity represented by a Service Principal.

```text
Terraform
    ↓
Service Principal
    ↓
Azure RBAC
    ↓
Azure Resources
```

Example role assignment:

```text
WHO:
Terraform Service Principal

WHAT:
Contributor

WHERE:
rg-app-dev
```

This allows automation to operate independently from an employee's personal account.

---

# Why Not Use a Personal User Account?

Production automation should not normally depend on a specific employee identity.

For example:

```text
CI/CD
  ↓
Tomislav's User Account
  ↓
Azure
```

creates unnecessary dependency on the employee account.

The account could:

- Be disabled
- Lose permissions
- Require interactive authentication
- Be affected by organizational changes
- Become unavailable when the employee leaves the company

A better model is:

```text
Automation
    ↓
Workload Identity
    ↓
RBAC
    ↓
Azure
```

---

# App Registration vs Service Principal

An App Registration and a Service Principal are related but different concepts.

For the current learning level, use the following mental model:

```text
App Registration
→ Application definition


Service Principal
→ Representation / identity of the application in a tenant
```

An App Registration contains configuration associated with an application identity.

A Service Principal represents that application in a Microsoft Entra tenant and can receive permissions.

---

# Tenant ID, Client ID and Client Secret

When applications authenticate to Microsoft Entra ID, several identifiers and credentials may be involved.

## Tenant ID

Identifies the Microsoft Entra tenant.

```text
Tenant ID
→ Which tenant?
```

## Client ID

Identifies the application.

```text
Client ID
→ Which application?
```

The Client ID is NOT the ID of an Azure VM, Resource Group, Storage Account, or another Azure resource receiving access.

## Client Secret

A Client Secret is one possible credential an application can use to authenticate.

```text
Client ID
+
Client Secret
      ↓
Application authentication
```

Client secrets introduce operational and security responsibilities.

They must be:

- Stored securely
- Protected from exposure
- Rotated when required
- Replaced when expired
- Kept out of source control

For this reason, passwordless or managed authentication approaches are preferred where appropriate.

---

# Managed Identity

A Managed Identity provides an identity to a supported Azure workload without requiring us to manage credentials such as client secrets.

Example:

```text
Azure VM
   ↓
Managed Identity
   ↓
Azure RBAC
   ↓
Key Vault
```

The important distinction is:

```text
Managed Identity
→ Identity


Azure RBAC
→ Authorization
```

Managed Identity does not automatically provide access to another Azure resource.

The identity must still receive the appropriate authorization.

---

# Why Use Managed Identity?

Consider an application running on an Azure VM that needs access to Key Vault.

One possible approach would require application credentials:

```text
VM
 ↓
Application credentials
 ↓
Microsoft Entra ID
 ↓
Key Vault
```

Those credentials must then be securely managed.

With Managed Identity:

```text
Application
    ↓
Azure VM
    ↓
Managed Identity
    ↓
Microsoft Entra ID
    ↓
Azure RBAC
    ↓
Key Vault
```

Azure manages the underlying identity credentials.

This reduces the need to store and manage secrets in:

- Application configuration
- Environment variables
- Deployment pipelines
- Source code
- Git repositories

---

# Managed Identity and RBAC

Enabling Managed Identity does not automatically give an Azure resource permission to access other resources.

For example:

```text
VM
 ↓
Managed Identity
```

only establishes the workload identity.

To read Key Vault secrets, authorization is also required.

Example:

```text
WHO:
VM Managed Identity

WHAT:
Key Vault Secrets User

WHERE:
Key Vault
```

Complete flow:

```text
Azure VM
    ↓
Managed Identity
    ↓
Key Vault Secrets User
    ↓
Key Vault
```

---

# System-Assigned Managed Identity

A system-assigned Managed Identity is tied to the lifecycle of one Azure resource.

Example:

```text
VM1
 │
 └── System-assigned Managed Identity
```

When the resource is deleted, its system-assigned identity is also deleted.

```text
Create VM
   ↓
Identity exists


Delete VM
   ↓
Identity deleted
```

Mental model:

```text
Resource lifecycle
        =
Identity lifecycle
```

A system-assigned Managed Identity is useful when an identity belongs specifically to one resource.

---

# User-Assigned Managed Identity

A user-assigned Managed Identity is created as a separate Azure resource.

It has an independent lifecycle and can be associated with multiple supported Azure resources.

Example:

```text
User-assigned Managed Identity
             │
        ┌────┼────┐
        ▼    ▼    ▼
       VM1  VM2  VM3
```

If VM1 is deleted:

```text
VM1 deleted
     ↓
Managed Identity remains
     ↓
VM2 and VM3 can continue using it
```

This makes user-assigned Managed Identities useful when multiple supported workloads need to share the same identity.

---

# System-Assigned vs User-Assigned

```text
SYSTEM-ASSIGNED

Azure Resource
      │
      └── Identity

Delete Resource
      ↓
Identity deleted
```

```text
USER-ASSIGNED

Managed Identity
      │
      ├── Resource 1
      ├── Resource 2
      └── Resource 3

Delete Resource 1
      ↓
Identity remains
```

A useful interview answer is:

> A system-assigned Managed Identity is tied to the lifecycle of one Azure resource, while a user-assigned Managed Identity is a standalone Azure resource with an independent lifecycle that can be associated with multiple supported resources.

---

# Service Principal vs Managed Identity

The simplified decision model is:

```text
Where does the workload run?
             │
      ┌──────┴──────┐
      │             │
Supported Azure   External application
workload          or automation
      │             │
      ▼             ▼
Managed Identity  Service Principal /
                  workload identity
```

For supported Azure workloads, Managed Identity is generally preferred because Azure manages the identity credentials.

Examples:

```text
Azure VM
→ Managed Identity

Azure App Service
→ Managed Identity

Azure Function
→ Managed Identity
```

For external applications or automation requiring an application identity in the Entra tenant:

```text
External Application
        ↓
Service Principal
        ↓
RBAC
        ↓
Azure
```

This is a simplified mental model. Modern external CI/CD systems can also use federated workload identity instead of long-lived client secrets.

---

# Terraform Examples

## Terraform Running Locally

During development, Terraform can use the developer's authenticated Azure CLI session.

```text
Developer
    ↓
az login
    ↓
User Identity
    ↓
Terraform
    ↓
Azure
```

This is acceptable for local learning and development.

---

## Terraform Automation Outside Azure

Automation should not depend on a developer's personal account.

Conceptually:

```text
External CI/CD
     ↓
Terraform
     ↓
Workload Identity
     ↓
RBAC
     ↓
Azure
```

A Service Principal is a traditional workload identity used for this scenario.

Modern CI/CD platforms can use federated authentication instead of storing a long-lived client secret.

Federated identity and OIDC will be covered later in the CI/CD section.

---

## Terraform Running on an Azure Workload

If Terraform runs from a supported Azure workload, Managed Identity may be used.

Example:

```text
Azure VM
   ↓
Managed Identity
   ↓
Terraform
   ↓
Azure RBAC
   ↓
Azure Resources
```

This avoids managing a Service Principal client secret on the VM.

---

# Key Vault Example

An application running on an Azure VM needs to read a database secret from Key Vault.

Preferred identity design:

```text
Application
    ↓
Azure VM
    ↓
Managed Identity
    ↓
Azure RBAC
    ↓
Key Vault
    ↓
Secret
```

Example authorization:

```text
WHO:
VM Managed Identity

WHAT:
Key Vault Secrets User

WHERE:
Key Vault
```

The identity and authorization are separate concepts:

```text
Managed Identity
→ WHO


Key Vault Secrets User
→ WHAT


Key Vault
→ WHERE
```

---

# Identity vs Networking

Identity and network connectivity solve different security problems.

For example:

```text
Can the VM reach Key Vault?
        ↓
Networking


Who is the VM?
        ↓
Managed Identity


Can the VM identity read secrets?
        ↓
Azure RBAC
```

A secure architecture may use both identity controls and network controls.

They should not be treated as the same mechanism.

---

# Decision Guide

Use this simplified model when choosing an identity:

```text
Human performing work manually
        ↓
User Identity


External application / automation
        ↓
Service Principal / workload identity


Supported Azure workload
        ↓
Managed Identity
```

Then determine authorization separately:

```text
Identity
   ↓
RBAC Role
   ↓
Scope
```

---

# Enterprise Mental Model

```text
                    MICROSOFT ENTRA ID
                           │
             ┌─────────────┴─────────────┐
             │                           │
             ▼                           ▼
       HUMAN IDENTITIES            WORKLOAD IDENTITIES
             │                           │
           Users                 Service Principals
                                 Managed Identities
             │                           │
             └─────────────┬─────────────┘
                           │
                           ▼
                       Azure RBAC
                           │
                           ▼
                       Azure Scope
                           │
                           ▼
                     Azure Resources
```

---

# Interview Questions

1. What is a Service Principal?
2. Is a Service Principal an identity or an authorization mechanism?
3. Why should production automation avoid using employee accounts?
4. What is the difference between a Service Principal and Azure RBAC?
5. What is the difference between an App Registration and a Service Principal?
6. What does a Client ID identify?
7. What is a Client Secret?
8. Why can client secrets become an operational and security concern?
9. What is a Managed Identity?
10. What is the main advantage of Managed Identity?
11. Does Managed Identity automatically provide access to Azure resources?
12. What is the difference between system-assigned and user-assigned Managed Identity?
13. When would you use a user-assigned Managed Identity?
14. How would an application running on an Azure VM securely access Key Vault?
15. Why would Managed Identity generally be preferred over a Service Principal with a client secret for a supported Azure workload?
16. How could Terraform authenticate when running locally?
17. Why should CI/CD Terraform deployments use a workload identity instead of a developer account?
18. What is the relationship between identity and Azure RBAC?
19. What is the difference between identity security and network security?
20. What does WHO + WHAT + WHERE represent?

---

# Key Takeaways

- Service Principal is an identity representing an application or workload in a Microsoft Entra tenant.
- Service Principal answers WHO, not WHAT the application can do.
- Azure RBAC provides authorization.
- App Registration represents the application definition.
- Service Principal represents the application in a tenant.
- Client ID identifies the application.
- Client Secret is one possible application credential.
- Managed Identity provides an identity to supported Azure workloads without requiring us to manage credentials such as client secrets.
- Managed Identity still requires appropriate authorization.
- System-assigned Managed Identity is tied to one resource's lifecycle.
- User-assigned Managed Identity has an independent lifecycle and can be associated with multiple supported resources.
- For supported Azure workloads, prefer Managed Identity where appropriate.
- External automation should use a workload identity instead of a personal user account.
- Terraform running locally can use the developer's Azure CLI authentication during development.
- Identity answers WHO.
- RBAC determines WHAT the identity can do and WHERE.
