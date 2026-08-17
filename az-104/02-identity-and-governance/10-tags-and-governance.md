# Azure Tags and Governance

## Overview

Azure Tags are key-value metadata used to organize, categorize, identify, and analyze Azure resources.

Example:

```text
Environment = Production
Owner       = DevOps-Team
CostCenter  = CC-1001
Application = WebShop
```

Tags do not provide permissions and are not security boundaries.

A simple mental model is:

```text
Tags
→ Metadata

RBAC
→ Permissions

Azure Policy
→ Governance rules

Resource Locks
→ Protection from modification/deletion
```

---

# Azure Tags

A tag consists of:

```text
Key = Value
```

Example:

```text
VM: vm-web-prod-01

Environment = Production
Application = WebShop
Owner       = Platform-Team
CostCenter  = CC-1001
```

Tags provide additional information about resources but do not change the functionality of the resource.

---

# Why Use Tags?

Tags are commonly used for:

- Resource organization
- Environment identification
- Ownership
- Cost management
- Reporting
- Automation
- Governance

Example:

```text
Environment = Production
Department  = Finance
Project     = WebShop
CostCenter  = CC-1001
```

This makes it easier to categorize and analyze large Azure environments.

---

# Tags and Cost Management

Tags can help categorize resources for cost analysis and reporting.

Example:

```text
VM1
CostCenter = Finance

SQL1
CostCenter = Finance

VM2
CostCenter = Marketing
```

This can help answer questions such as:

```text
How much do Finance resources cost?

How much does Project X cost?

How much does the Production environment cost?
```

A common enterprise approach is:

```text
CostCenter  = CC-1001
Project     = WebShop
Environment = Production
```

---

# Resource Groups vs Tags

A Resource Group is a logical container and management scope for Azure resources.

```text
rg-app-prod
│
├── VM
├── Storage Account
└── Key Vault
```

A Tag is metadata associated with a resource or supported Azure object.

```text
VM
│
├── Environment = Production
├── Owner = Platform-Team
└── CostCenter = CC-1001
```

Mental model:

```text
Resource Group
→ Logical container / management scope

Tag
→ Metadata / categorization
```

---

# Tags Are Not RBAC

Tags do not grant or deny access.

For example:

```text
Department = Finance
```

does NOT mean that Finance employees automatically have access to the resource.

Access is controlled through authorization mechanisms such as Azure RBAC.

```text
Finance Security Group
        ↓
RBAC Role
        ↓
Azure Scope
```

Therefore:

```text
Tag
→ Describes/categorizes a resource

RBAC
→ Controls authorization
```

---

# Owner Tag vs Owner RBAC Role

These concepts have similar names but completely different meanings.

## Owner Tag

```text
Owner = Platform-Team
```

This is metadata.

It can indicate which team is responsible for the resource.

It does not grant Azure permissions.

## Owner RBAC Role

```text
Platform-Team
      ↓
Owner
      ↓
Resource Group
```

This is an Azure RBAC role assignment that grants broad management permissions at the assigned scope.

Therefore:

```text
Owner tag
→ Metadata

Owner RBAC role
→ Authorization
```

---

# Tag Inheritance

Tags do not automatically inherit from a parent scope simply because they exist there.

Example:

```text
rg-production
│
│ Environment = Production
│
└── VM
```

The VM does not automatically receive:

```text
Environment = Production
```

just because the Resource Group contains that tag.

Mental model:

```text
Parent has tag
      ↓
Child resource

Automatic inheritance?
→ NO
```

Azure Policy can be used to implement tag governance and inheritance scenarios.

---

# Tags and Azure Policy

Azure Policy can enforce or manage tagging requirements.

For example, an organization may require:

```text
Environment
CostCenter
Owner
```

on its Azure resources.

Azure Policy can help implement this governance.

Examples include:

```text
Audit
→ Report resources missing required tags

Deny
→ Block operations that violate a tag requirement

Modify
→ Add/change supported tags

Tag inheritance policy
→ Apply values from an appropriate parent scope
```

Therefore:

```text
TAG
→ Metadata

AZURE POLICY
→ Governance/enforcement
```

---

# Modify Example

Suppose every applicable resource should contain:

```text
Environment = Production
```

If the tag is missing, an appropriate Policy using the `Modify` effect can manage the tag.

```text
Resource request
      ↓
Environment tag missing
      ↓
Azure Policy
      ↓
Modify
      ↓
Environment = Production
```

Mental model:

```text
Missing/incorrect supported tag
→ MODIFY
```

---

# Naming Conventions vs Tags

Naming conventions and Tags can both help organize Azure resources.

Example resource name:

```text
vm-web-prod-weu-01
```

The name may communicate:

```text
VM
Web workload
Production
West Europe
Instance 01
```

Tags provide structured metadata:

```text
Environment = Production
Workload    = Web
Region      = WestEurope
Owner       = Platform-Team
```

Enterprise environments commonly use both:

```text
Naming conventions
        +
Tags
```

They complement each other.

---

# Tags Are Not Security Boundaries

A tag such as:

```text
Environment = Production
```

does not create a production security boundary.

Similarly:

```text
Owner = DevOps-Team
```

does not grant that team the Owner RBAC role.

Tags should primarily be viewed as:

```text
Metadata
Categorization
Organization
Reporting
Cost allocation
Automation inputs
Governance data
```

---

# Azure Governance Overview

Several Azure services and concepts work together to provide governance.

```text
AZURE GOVERNANCE
│
├── Management Groups
│     └── Organize subscriptions
│
├── Azure RBAC
│     └── Who can do what and where?
│
├── Azure Policy
│     └── What rules must resources follow?
│
├── Tags
│     └── Metadata and organization
│
└── Resource Locks
      └── Protection from modification/deletion
```

Each solves a different problem.

---

# Enterprise Governance Example

Consider:

```text
Management Group
      ↓
PROD Subscription
      ↓
rg-app-prod
      ↓
Application Resources
```

The organization has several requirements.

## Organize Subscriptions

Use:

```text
Management Groups
```

## Developers Can Manage Application Resources

Use:

```text
Azure RBAC

Developers
    ↓
Contributor
    ↓
rg-app-prod
```

## Resources Must Use Approved Regions

Use:

```text
Azure Policy

Allowed Locations
→ West Europe
```

## Identify Production Resources

Use:

```text
Tags

Environment = Production
```

## Protect Critical Database From Accidental Deletion

Use:

```text
Resource Lock

Production Database
      ↓
Delete Lock
```

---

# Governance Mental Model

The following mental model summarizes the main concepts:

```text
MANAGEMENT GROUPS
→ Organize subscriptions


RBAC
→ WHO can do WHAT and WHERE?


AZURE POLICY
→ WHAT RULES must resources follow?


TAGS
→ HOW do we categorize/describe resources?


RESOURCE LOCKS
→ HOW do we protect resources
  from modification/deletion?
```

---

# Interview Questions

1. What are Azure Tags?
2. What is the structure of an Azure Tag?
3. Give examples of common enterprise tags.
4. Why are Tags useful for cost management?
5. What is the difference between a Resource Group and a Tag?
6. Do Tags grant permissions?
7. What is the difference between an Owner tag and the Owner RBAC role?
8. Do Tags automatically inherit from Resource Groups to resources?
9. How can Azure Policy be used with Tags?
10. Which Policy effect can add/change supported tags?
11. Are Tags a security boundary?
12. What is the difference between naming conventions and Tags?
13. Why might an organization use both naming conventions and Tags?
14. How would you identify Production resources?
15. How would you enforce a required CostCenter tag?
16. What is the difference between Tags and Azure Policy?
17. What is the difference between Tags and Azure RBAC?
18. How do Tags help with governance?
19. Explain Management Groups vs RBAC vs Policy vs Tags vs Resource Locks.
20. Design a simple governance model for a DEV and PROD Azure environment.

---

# Key Takeaways

- Azure Tags are key-value metadata.
- Tags help organize and categorize Azure resources.
- Common tags include Environment, Owner, CostCenter, Project, and Application.
- Tags can help with cost analysis and reporting.
- Resource Groups are logical containers/management scopes; Tags are metadata.
- Tags do not grant permissions.
- An Owner tag is not the same as the Owner RBAC role.
- Tags do not automatically inherit from parent scopes.
- Azure Policy can implement tag governance and inheritance scenarios.
- Modify can be used to add or change supported tags.
- Tags are not security boundaries.
- Naming conventions and Tags complement each other.
- Management Groups organize subscriptions.
- Azure RBAC controls authorization.
- Azure Policy controls governance rules.
- Tags provide metadata.
- Resource Locks protect resources from modification/deletion.
