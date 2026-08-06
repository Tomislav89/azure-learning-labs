# Module 01 - Azure Global Infrastructure

This module covers the foundational architecture behind Microsoft Azure.

The goal is to understand how Azure is geographically organized, how resources are structured and governed, and how deployment requests are processed by Azure.

## Topics

| Lesson | Topic | Status |
|---|---|---|
| 01 | [Azure Global Infrastructure](./01-azure-global-infrastructure.md) | Completed |
| 02 | [Azure Resource Organization](./02-resource-organization.md) | Completed |
| 03 | [Azure Resource Manager](./03-azure-resource-manager.md) | Completed |
| 04 | [Azure Resource Providers](./04-resource-providers.md) | Completed |

## Key Concepts

This module introduces:

- Azure Geographies
- Azure Regions
- Availability Zones
- Region Pairs
- High Availability
- Disaster Recovery
- Microsoft Entra tenants
- Management Groups
- Subscriptions
- Resource Groups
- Azure Resource Manager
- Control Plane vs Data Plane
- Azure Resource Providers
- Resource Types
- Resource Provider registration

## Azure Resource Hierarchy

```text
Microsoft Entra Tenant
│
├── Management Groups
│
└── Subscriptions
    │
    └── Resource Groups
        │
        └── Azure Resources
```

Management Groups can be used above subscriptions to create a governance hierarchy across larger Azure environments.

## Deployment Flow

A simplified Azure deployment flow:

```text
Terraform / Azure CLI / Bicep / Azure Portal
                    │
                    ▼
          Azure Resource Manager
                    │
          Authentication
          Authorization
          Validation
                    │
                    ▼
          Azure Resource Provider
                    │
                    ▼
              Azure Resource
```

## Practical Work

Hands-on exercises for this module are stored in:

```text
labs/
```

Architecture diagrams are stored in:

```text
diagrams/
```

Supporting files and images are stored in:

```text
assets/
```
