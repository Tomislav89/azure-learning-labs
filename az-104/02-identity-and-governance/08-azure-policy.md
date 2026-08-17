# Azure Policy

## Overview

Azure Policy is an Azure governance service used to define and enforce rules that Azure resources must follow.

Examples of governance requirements include:

- Resources can only be deployed to approved regions
- Resources must contain required tags
- Only approved VM SKUs can be used
- Only approved resource types can be deployed
- Required configurations must exist

A simple mental model is:

```text
Azure RBAC
→ WHO can do WHAT and WHERE?

Azure Policy
→ WHAT RULES must resources comply with?
```

---

# Azure Policy Example

An organization allows resources only in West Europe.

```text
Policy:
Allowed Locations = West Europe
```

A user attempts to create:

```text
VM
Location: East US
```

Azure Policy evaluates the deployment:

```text
Deployment request
       ↓
Policy evaluation
       ↓
Location allowed?
       ↓
      NO
       ↓
Deployment denied
```

---

# Azure RBAC vs Azure Policy

Azure RBAC controls authorization.

Example:

```text
Developers
    ↓
Contributor
    ↓
rg-app-dev
```

This determines who can perform operations and at which scope.

Azure Policy controls resource compliance.

Example:

```text
rg-app-dev
    ↓
Allowed Locations
    ↓
West Europe
```

Therefore:

```text
RBAC
→ WHO can perform an operation?

Policy
→ Does the resource comply with organizational rules?
```

Having RBAC permissions does not allow a user to bypass an Azure Policy.

Example:

```text
Alice
 ↓
Contributor
 ↓
DEV Subscription

        +

Policy
 ↓
Only West Europe allowed
```

Alice attempts:

```text
Create VM
Location: East US
```

Result:

```text
RBAC
→ Alice can create VMs
→ PASS

Policy
→ East US is not allowed
→ FAIL

Deployment
→ DENIED
```

---

# Policy Definition

A Policy Definition describes a governance rule.

Examples:

```text
Allowed Locations

Required Tags

Allowed VM SKUs

Allowed Resource Types
```

Mental model:

```text
Policy Definition
→ WHAT is the rule?
```

---

# Policy Assignment

A Policy Definition must be assigned to a scope for it to apply.

Example:

```text
Policy Definition
Allowed Locations = West Europe

        +

Policy Assignment
DEV Subscription
```

Mental model:

```text
Policy Definition
→ WHAT is the rule?

Policy Assignment
→ WHERE is the rule applied?
```

---

# Policy Scope

Azure Policy can be assigned at different scopes.

```text
Management Group
       ↓
Subscription
       ↓
Resource Group
       ↓
Resource
```

Assignments at higher scopes can affect resources in child scopes.

Example:

```text
Management Group
       │
       │ Policy Assignment
       ↓
Subscription
       ↓
Resource Group
       ↓
Resources
```

This makes Azure Policy useful for enforcing organization-wide governance standards.

---

# Policy Effects

A Policy Definition contains an effect that determines what happens when the policy condition is matched.

Important effects include:

```text
Deny

Audit

Modify

DeployIfNotExists

AuditIfNotExists

Append

Disabled
```

For AZ-104, the most important mental model is:

```text
Deny
→ BLOCK

Audit
→ REPORT

Modify
→ CHANGE

DeployIfNotExists
→ DEPLOY MISSING CONFIGURATION
```

---

# Deny

`Deny` prevents an operation that violates the policy.

Example:

```text
Policy:
Only West Europe allowed
```

Attempt:

```text
Create VM
East US
```

Result:

```text
Policy violation
      ↓
DENY
      ↓
Deployment blocked
```

Mental model:

```text
Deny
→ STOP
```

---

# Audit

`Audit` does not block the operation.

Instead, the resource can be reported as non-compliant.

```text
Resource violates policy
        ↓
AUDIT
        ↓
Resource can exist
        ↓
Reported as non-compliant
```

Mental model:

```text
Audit
→ ALLOW + REPORT
```

This is useful when an organization first wants visibility into compliance before enforcing stricter controls.

---

# Modify

`Modify` can add, update, or remove supported resource properties or tags according to the Policy Definition.

A common example is tag management.

```text
Resource request
      ↓
Environment tag missing
      ↓
MODIFY
      ↓
Environment = Production
```

Mental model:

```text
Modify
→ Change/add supported property or tag
```

Existing resources may require remediation to bring them into compliance.

---

# DeployIfNotExists

`DeployIfNotExists` can trigger deployment of required related resources or configuration when they are missing.

Example:

```text
VM
 ↓
Required monitoring configuration exists?
 ↓
NO
 ↓
DeployIfNotExists
 ↓
Deploy required configuration
```

Mental model:

```text
Required related resource/configuration missing?
        ↓
Deploy it
```

Policy assignments using this type of remediation may require an appropriate managed identity and permissions.

---

# Modify vs DeployIfNotExists

These two effects can easily be confused.

Use this mental model:

```text
Missing / incorrect tag or supported property
        ↓
MODIFY
```

versus:

```text
Required related resource/configuration missing
        ↓
DEPLOY IF NOT EXISTS
```

Example:

```text
Environment tag missing
→ Modify

Monitoring configuration missing
→ DeployIfNotExists
```

---

# Deny vs Audit vs Modify vs DeployIfNotExists

```text
Wrong region
     ↓
DENY
→ Block deployment


Policy violation where we only want visibility
     ↓
AUDIT
→ Report non-compliance


Missing/incorrect supported tag/property
     ↓
MODIFY
→ Change it


Missing required related configuration/resource
     ↓
DEPLOY IF NOT EXISTS
→ Deploy it
```

---

# Policy Initiative

A Policy Initiative is a collection of multiple Policy Definitions.

Instead of managing many individual policies separately:

```text
Policy 1
Policy 2
Policy 3
Policy 4
```

we can group them:

```text
Company Governance Initiative
│
├── Allowed Locations
├── Required Tags
├── Allowed VM SKUs
└── Monitoring Requirements
```

Mental model:

```text
Policy Definition
→ One rule

Policy Initiative
→ Collection of rules
```

The initiative can then be assigned to an appropriate scope.

---

# Policy Compliance

Azure Policy evaluates resources for compliance.

Resources can be reported as:

```text
COMPLIANT
```

or:

```text
NON-COMPLIANT
```

Example:

```text
Policy:
Environment tag required


VM1
Environment = Production
→ COMPLIANT


VM2
Environment tag missing
→ NON-COMPLIANT
```

This provides visibility into whether infrastructure follows organizational standards.

---

# Enterprise Example

An organization requires:

```text
Resources only in approved regions

Environment tags

Approved VM SKUs

Required monitoring configuration
```

These rules can be grouped into an initiative:

```text
Company Governance Initiative
│
├── Allowed Locations
├── Required Environment Tag
├── Allowed VM SKUs
└── Monitoring Configuration
```

The initiative could then be assigned at a higher governance scope:

```text
Management Group
       ↓
Company Governance Initiative
       ↓
Subscriptions
       ↓
Resource Groups
       ↓
Resources
```

---

# RBAC + Policy Example

Requirement:

```text
Developers can manage resources
only in rg-app-dev.

Resources must contain
Environment tag.
```

RBAC handles developer permissions:

```text
Developers
    ↓
Contributor
    ↓
rg-app-dev
```

Azure Policy handles the resource requirement:

```text
Azure Policy
    ↓
Environment tag requirement
    ↓
rg-app-dev
```

Together:

```text
Developer
    ↓
RBAC
    ↓
Can user perform the operation?
    ↓
YES
    ↓
Azure Policy
    ↓
Does resource comply with policy?
    ↓
YES
    ↓
Operation proceeds
```

---

# Governance Mental Model

Azure governance combines multiple services and concepts.

```text
Management Groups
→ Organize subscriptions

Azure RBAC
→ Who can do what and where?

Azure Policy
→ What rules must resources follow?

Tags
→ Resource metadata and organization

Resource Locks
→ Protect resources from modification/deletion
```

---

# Interview Questions

1. What is Azure Policy?
2. What is the difference between Azure Policy and Azure RBAC?
3. Can a Contributor bypass an Azure Policy?
4. What is a Policy Definition?
5. What is a Policy Assignment?
6. At which scopes can Azure Policy be assigned?
7. What happens when a policy is assigned at Management Group scope?
8. What does the Deny effect do?
9. What does the Audit effect do?
10. What is the difference between Deny and Audit?
11. What does Modify do?
12. What does DeployIfNotExists do?
13. What is the difference between Modify and DeployIfNotExists?
14. Which effect could be used to manage a missing tag?
15. Which effect could deploy missing required configuration?
16. What is a Policy Initiative?
17. What is policy compliance?
18. What does non-compliant mean?
19. How would you restrict Azure deployments to approved regions?
20. How would you combine RBAC and Policy in an enterprise environment?

---

# Key Takeaways

- Azure Policy defines and enforces governance rules for Azure resources.
- Azure RBAC controls who can perform operations and at which scope.
- Azure Policy controls what rules resources must comply with.
- RBAC permissions do not bypass Azure Policy.
- Policy Definition defines the rule.
- Policy Assignment determines where the rule applies.
- Policy assignments can apply across Azure governance scopes.
- Deny blocks non-compliant operations.
- Audit reports non-compliance without blocking the operation.
- Modify can change supported properties or tags.
- DeployIfNotExists can deploy missing related resources or configuration.
- Policy Initiative groups multiple Policy Definitions.
- Azure Policy provides compliance visibility.
- Policy assignments at higher scopes can affect child scopes.
