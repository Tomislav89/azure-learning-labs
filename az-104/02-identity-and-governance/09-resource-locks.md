# Azure Resource Locks

## Overview

Azure Resource Locks protect Azure resources from accidental deletion or modification.

Azure provides two lock types:

```text
Resource Locks
│
├── CanNotDelete (Delete)
│
└── ReadOnly
```

The main mental model is:

```text
Delete Lock
→ Prevent deletion

ReadOnly Lock
→ Prevent modification and deletion
```

Resource Locks primarily affect management-plane operations.

---

# Delete Lock

A Delete lock is also known as `CanNotDelete`.

It prevents deletion while still allowing the resource to be read and modified.

```text
Delete Lock

READ    → Allowed
MODIFY  → Allowed
DELETE  → Blocked
```

Example:

```text
Production Database
        ↓
Delete Lock
        ↓
Read configuration    → Allowed
Modify configuration  → Allowed
Delete database       → Blocked
```

This is useful for important resources that administrators still need to manage but should not accidentally delete.

---

# ReadOnly Lock

A ReadOnly lock is more restrictive.

```text
ReadOnly Lock

READ    → Allowed
MODIFY  → Blocked
DELETE  → Blocked
```

Example:

```text
Azure Resource
      ↓
ReadOnly Lock
      ↓
Read resource    → Allowed
Modify resource  → Blocked
Delete resource  → Blocked
```

ReadOnly locks should be used carefully because they can interfere with management operations required by some Azure services.

---

# Delete vs ReadOnly

The key difference is:

| Operation | Delete Lock | ReadOnly Lock |
|---|---|---|
| Read | Allowed | Allowed |
| Modify | Allowed | Blocked |
| Delete | Blocked | Blocked |

Mental model:

```text
DELETE LOCK
→ No DELETE

READONLY LOCK
→ No MODIFY
→ No DELETE
```

---

# Resource Lock Scope

Resource Locks can be applied at different Azure scopes, including:

```text
Subscription
     ↓
Resource Group
     ↓
Resource
```

Locks applied at a parent scope are inherited by resources below that scope.

Example:

```text
rg-production
│
│ Delete Lock
│
├── VM
├── Storage Account
└── Key Vault
```

Resources inside `rg-production` are affected by the inherited lock.

---

# Resource Group Example

Consider:

```text
rg-production
│
├── VM
├── Storage Account
└── SQL Database
```

If a Delete lock is applied to:

```text
rg-production
```

the lock protects resources within that scope from deletion.

This prevents someone from simply deleting the Resource Group to bypass protection of its resources.

---

# Resource Locks and Azure RBAC

Azure RBAC and Resource Locks solve different problems.

Azure RBAC determines:

```text
WHO
can do
WHAT
and
WHERE
```

Resource Locks protect resources against specific management operations.

Example:

```text
Alice
 ↓
Owner
 ↓
rg-production
```

Normally, Owner provides broad management permissions.

However:

```text
VM
 ↓
Delete Lock
```

Alice attempts:

```text
Delete VM
```

Result:

```text
RBAC
→ Alice has permission

Resource Lock
→ Delete operation blocked

Result
→ VM is not deleted
```

Having an Owner role does not allow a user to simply bypass an existing Resource Lock.

A user with appropriate permissions to manage locks may remove the lock first and then perform the operation.

---

# Resource Locks and the Control Plane

Resource Locks primarily affect Azure management-plane operations.

Examples of control-plane operations include:

```text
Create resource

Modify resource configuration

Delete resource

Manage resource properties
```

These operations typically go through Azure Resource Manager.

A useful mental model is:

```text
Resource Lock
      ↓
ARM
      ↓
Control Plane
```

---

# Control Plane vs Data Plane

Resource Locks should not automatically be interpreted as data protection.

Consider an Azure Storage Account:

```text
Storage Account
      │
      └── Blob Container
            │
            ├── file1.txt
            └── image.jpg
```

There are two different types of operations.

## Control Plane

Operations on the Azure Storage Account resource itself.

Examples:

```text
Modify Storage Account configuration

Delete Storage Account

Change management properties
```

A ReadOnly lock can block these management operations.

---

## Data Plane

Operations involving the actual data stored by the service.

Examples can include:

```text
Read blob

Upload blob

Modify blob

Delete blob
```

Data-plane access is controlled separately by the service's authorization mechanisms and behavior.

Therefore:

```text
ReadOnly Resource Lock
        ≠
All stored data automatically becomes read-only
```

This distinction is important.

---

# Storage Account Example

Suppose:

```text
Storage Account
      ↓
ReadOnly Lock
```

For management-plane operations:

```text
Read Storage Account configuration
→ Allowed

Modify Storage Account configuration
→ Blocked

Delete Storage Account
→ Blocked
```

However, we cannot automatically conclude:

```text
Blob data cannot be modified
```

because blob operations can occur through the data plane.

Mental model:

```text
CONTROL PLANE
→ Resource Locks

DATA PLANE
→ Separate authorization/service behavior
```

---

# Resource Locks vs Azure Policy

Azure Policy and Resource Locks also solve different problems.

## Azure Policy

```text
What rules must resources comply with?
```

Example:

```text
Resources must be deployed
only in West Europe
```

## Resource Lock

```text
Protect an existing resource
against modification/deletion
```

Example:

```text
Production Database
      ↓
Delete Lock
```

Therefore:

```text
Azure Policy
→ Governance rules

Resource Locks
→ Protection against management operations
```

---

# RBAC vs Policy vs Resource Locks

These three concepts should be clearly separated.

```text
RBAC
→ WHO can do WHAT and WHERE?


Azure Policy
→ WHAT RULES must resources follow?


Resource Locks
→ Protect resources against
  modification/deletion
```

Example:

```text
Developers
    ↓
Contributor
    ↓
rg-production
       ← RBAC


Resources
    ↓
West Europe only
       ← Azure Policy


Production Database
    ↓
Delete Lock
       ← Resource Lock
```

Each mechanism solves a different governance or security problem.

---

# Production Database Scenario

Consider a critical production database.

Administrators need to:

```text
Read configuration

Modify configuration
```

but we want protection against:

```text
Accidental deletion
```

The appropriate choice is:

```text
Production Database
        ↓
Delete Lock
```

because:

```text
READ    → Allowed
MODIFY  → Allowed
DELETE  → Blocked
```

A ReadOnly lock would be unnecessarily restrictive because administrators would also be prevented from performing management-plane modifications.

---

# Terraform Scenario

Resource Locks can also protect important resources from accidental infrastructure operations.

For example:

```text
Terraform
    ↓
terraform destroy
    ↓
Azure Resource Manager
    ↓
Resource has Delete Lock
    ↓
Delete operation blocked
```

The lock must be appropriately handled or removed before the protected management operation can succeed.

This provides an additional protection layer for critical resources.

---

# Governance Mental Model

Resource Locks complement other Azure governance controls:

```text
Management Groups
→ Organize subscriptions

Azure RBAC
→ Who can do what and where?

Azure Policy
→ What rules must resources follow?

Resource Locks
→ Protect against modification/deletion

Tags
→ Resource metadata and organization
```

These mechanisms should not be treated as replacements for one another.

---

# Interview Questions

1. What are Azure Resource Locks?
2. What are the two types of Resource Locks?
3. What is a CanNotDelete/Delete lock?
4. What operations are allowed with a Delete lock?
5. What operations are allowed with a ReadOnly lock?
6. What is the difference between Delete and ReadOnly locks?
7. At which scopes can Resource Locks be applied?
8. Are Resource Locks inherited from a parent scope?
9. What happens when a Delete lock is applied to a Resource Group?
10. Can an Owner simply bypass a Resource Lock?
11. What is the difference between Azure RBAC and Resource Locks?
12. What is the difference between Azure Policy and Resource Locks?
13. Do Resource Locks primarily affect the control plane or data plane?
14. Does a ReadOnly lock on a Storage Account automatically make all blobs read-only?
15. Why is the control-plane vs data-plane distinction important for Resource Locks?
16. Which lock would you use for a production database that must remain configurable but must not be accidentally deleted?
17. Can a Resource Lock block an Azure Resource Manager delete operation?
18. How could a Resource Lock affect `terraform destroy`?
19. Explain RBAC vs Policy vs Resource Locks.
20. When would you use a ReadOnly lock instead of a Delete lock?

---

# Key Takeaways

- Resource Locks protect Azure resources from accidental deletion or modification.
- Azure provides CanNotDelete/Delete and ReadOnly locks.
- Delete allows read and modification but prevents deletion.
- ReadOnly allows reading but prevents management-plane modification and deletion.
- Locks applied at parent scopes are inherited by resources below that scope.
- Owner permissions do not automatically bypass an existing lock.
- Resource Locks primarily affect control-plane operations.
- Control-plane and data-plane operations are different.
- A ReadOnly Storage Account lock does not automatically mean all blob data becomes read-only.
- RBAC controls who can do what and where.
- Azure Policy controls governance rules.
- Resource Locks protect against management operations.
- Delete locks are useful for critical resources that still need to remain configurable.
