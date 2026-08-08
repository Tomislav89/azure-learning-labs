# Module 02 - Identity and Governance

## Overview

This module covers identity, access management, and governance concepts in Microsoft Azure.

The focus is on understanding how Microsoft Entra ID manages identities and authentication, how access to Azure resources is controlled, and how governance mechanisms are applied across Azure environments.

## Topics

| Lesson | Topic | Status |
|---|---|---|
| 01 | [Microsoft Entra ID Fundamentals](./01-microsoft-entra-id-fundamentals.md) | Completed |
| 02 | Users and Groups | Planned |
| 03 | Azure RBAC | Planned |
| 04 | Administrative Roles | Planned |
| 05 | Managed Identities and Service Principals | Planned |
| 06 | Azure Policy | Planned |
| 07 | Resource Locks | Planned |
| 08 | Tags | Planned |

The module structure may evolve as additional AZ-104 identity and governance topics are covered.

## Key Areas

This module covers:

- Microsoft Entra ID
- Users and groups
- Internal and external identities
- Cloud and hybrid identities
- Authentication and authorization
- Azure Role-Based Access Control (RBAC)
- Service Principals
- Managed Identities
- Azure governance
- Azure Policy
- Resource Locks
- Tags

## Identity and Resource Model

```text
Microsoft Entra Tenant
        │
        ├── Users
        ├── Groups
        └── Workload Identities
                │
                │ Authentication
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

## Documentation Structure

Each major topic is documented in a separate Markdown file.

Hands-on exercises will be stored in dedicated lab directories when applicable.

The documentation focuses on:

- Core concepts
- Architecture and relationships
- Azure CLI examples
- Terraform examples
- Enterprise practices
- Interview preparation
