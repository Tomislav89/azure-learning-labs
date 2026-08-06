# Azure Resource Organization

## Overview

Azure resources are organized using a hierarchy that provides boundaries for identity, billing, access control, governance, and lifecycle management.

The main concepts are:

```text
Microsoft Entra Tenant
        │
Management Groups
        │
Subscriptions
        │
Resource Groups
        │
Resources
```

## Microsoft Entra Tenant

A Microsoft Entra tenant is the identity boundary of an organization.

It contains identity objects such as:

- Users
- Groups
- Applications
- Service Principals
- Managed Identities

Azure subscriptions are associated with a Microsoft Entra tenant for authentication and identity management.

A useful mental model is:

> A tenant answers the question: "Who are you?"

## Management Groups

Management Groups provide a governance hierarchy above Azure subscriptions.

They are useful when an organization operates multiple subscriptions.

Example:

```text
Tenant
│
├── Platform
│   ├── Identity Subscription
│   └── Management Subscription
│
├── Production
│   ├── Production EU
│   └── Production US
│
└── Development
    ├── Development
    └── Sandbox
```

Management Groups allow governance controls to be applied at a higher scope.

Examples include:

- Azure Policy
- RBAC assignments

Assignments at higher scopes can be inherited by child scopes.

## Azure Subscription

An Azure subscription provides an important management boundary.

It acts as a:

- Billing boundary
- Access management scope
- Governance scope
- Quota boundary for many Azure services

Organizations commonly use multiple subscriptions to separate:

- Production
- Development
- Testing
- Sandbox environments
- Business units
- Workloads

## Resource Groups

A Resource Group is a logical container for Azure resources.

Resources with a similar lifecycle are commonly placed in the same Resource Group.

For example:

```text
rg-application-dev
│
├── App Service
├── Storage Account
├── Key Vault
└── Monitoring resources
```

If the complete development environment is no longer required, the Resource Group can be removed together with its resources.

## Resource Group Scope

Resource Groups can also provide a scope for:

- RBAC
- Azure Policy
- Resource Locks
- Tags

A single Azure resource belongs to one Resource Group at a time.

Resources within the same Resource Group can be located in different Azure regions.

The Resource Group itself also has a location used for its metadata.

## Lifecycle-Based Organization

Resources should generally be grouped according to how they are managed rather than simply according to their resource type.

Good example:

```text
rg-webapp-dev
├── Application
├── Storage
├── Key Vault
└── Monitoring
```

Potentially poor organization:

```text
rg-all-storage
rg-all-vms
rg-all-keyvaults
```

The second approach can make application lifecycle management more difficult because related resources are distributed across unrelated Resource Groups.

## Common Mistakes

### Resource Group is a billing boundary

Not exactly.

A subscription is the primary Azure billing boundary. Resource Groups can still be useful for cost analysis and organization.

### Resources in one Resource Group must use the same region

Incorrect.

Resources within a Resource Group can exist in different regions.

### One resource can belong to multiple Resource Groups

Incorrect.

A resource belongs to one Resource Group at a time.

## Interview Questions

1. What is the primary responsibility of a Microsoft Entra tenant?
2. Why would an enterprise use Management Groups?
3. Why is an Azure subscription an important billing and access boundary?
4. What is the purpose of a Resource Group?
5. Why should resources often be grouped by lifecycle?
6. Can one Azure resource belong to multiple Resource Groups?
7. Can resources within the same Resource Group exist in different regions?

## Key Takeaways

- Microsoft Entra tenant provides the identity boundary.
- Management Groups provide governance across subscriptions.
- Subscriptions provide billing and management boundaries.
- Resource Groups logically organize Azure resources.
- Resource lifecycle is an important consideration when designing Resource Groups.
