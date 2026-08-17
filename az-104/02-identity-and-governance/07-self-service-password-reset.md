# Self-Service Password Reset (SSPR)

## Overview

Self-Service Password Reset (SSPR) allows users to reset or change their password without requiring administrator or Help Desk intervention.

A simplified flow is:

```text
User forgets password
        ↓
SSPR
        ↓
Identity verification
        ↓
Password reset
```

SSPR reduces Help Desk workload and allows users to recover access to their accounts more quickly.

---

# Why Use SSPR?

Without SSPR:

```text
User forgets password
        ↓
Help Desk ticket
        ↓
Administrator verifies user
        ↓
Administrator resets password
```

With SSPR:

```text
User forgets password
        ↓
Identity verification
        ↓
SSPR
        ↓
New password
```

Main benefits include:

- Reduced Help Desk workload
- Faster account recovery
- Less dependency on administrators for password resets
- Improved user experience

---

# Identity Verification

SSPR does not allow users to reset passwords without proving their identity.

The user must first satisfy the configured identity verification requirements.

```text
User
 ↓
SSPR request
 ↓
Identity verification
 ↓
Verification successful
 ↓
Password reset
```

Therefore:

```text
SSPR
≠
Password reset without authentication
```

Instead:

```text
SSPR
=
Self-service password reset
after identity verification
```

---

# Authentication Methods

Users can verify their identity using supported authentication methods configured by the organization.

Depending on the environment and configuration, these can include methods such as:

- Microsoft Authenticator
- Mobile phone
- Email in supported scenarios
- Security questions in supported SSPR scenarios

The important concept is:

```text
SSPR
 ↓
Verify identity
 ↓
Password reset
```

---

# SSPR and MFA

SSPR and MFA are related to identity security, but they have different purposes.

## MFA

Multi-Factor Authentication strengthens authentication by requiring multiple authentication factors.

```text
MFA
→ Stronger authentication
```

## SSPR

Self-Service Password Reset allows users to recover or reset their password after appropriate identity verification.

```text
SSPR
→ Password recovery/reset
```

Therefore:

```text
MFA
→ Protect authentication

SSPR
→ Provide self-service password recovery
```

They should not be treated as the same feature.

---

# SSPR Scope

SSPR can be enabled for eligible users according to the organization's configuration.

This allows organizations to introduce SSPR gradually.

For example:

```text
Microsoft Entra ID
       │
       ├── Developers
       ├── Finance
       └── HR
```

An organization could initially enable SSPR for a selected population before expanding its use.

This can be useful for testing and controlled rollout.

---

# SSPR for Cloud Identities

For cloud identities, password management occurs within the Microsoft Entra environment.

A simplified flow is:

```text
Cloud User
    ↓
SSPR
    ↓
Identity verification
    ↓
New password
    ↓
Microsoft Entra ID
```

---

# SSPR in Hybrid Environments

Hybrid identity environments can include both:

```text
On-premises Active Directory

and

Microsoft Entra ID
```

A simplified architecture is:

```text
On-premises Active Directory
            ↓
      Synchronization
            ↓
     Microsoft Entra ID
```

If a user performs a supported password reset/change in the cloud, the organization may need that password change to be reflected in the on-premises Active Directory environment.

This is where password writeback becomes important.

---

# Password Writeback

Password writeback allows supported password changes or resets performed through Microsoft Entra ID to be written back to on-premises Active Directory.

Example:

```text
User
 ↓
Microsoft Entra SSPR
 ↓
Password reset
 ↓
Password Writeback
 ↓
On-premises Active Directory
```

This is particularly important in hybrid identity environments.

A useful interview definition is:

> Password writeback allows supported password changes or resets performed in Microsoft Entra ID to be written back to on-premises Active Directory.

---

# Synchronization vs Password Writeback

These concepts should not be confused.

## Synchronization

Simplified direction:

```text
On-premises AD
      ↓
Synchronization
      ↓
Microsoft Entra ID
```

Identity information is synchronized from the on-premises environment toward Microsoft Entra ID.

Password-related synchronization does not mean that a plain-text password is simply copied into the cloud.

---

## Password Writeback

Direction:

```text
Microsoft Entra ID
      ↓
Password Writeback
      ↓
On-premises AD
```

For example:

```text
Alice resets password using SSPR
             ↓
Microsoft Entra ID
             ↓
Password Writeback
             ↓
On-premises AD
```

The easiest mental model is:

```text
Synchronization
On-prem → Cloud

Password Writeback
Cloud → On-prem
```

---

# Hybrid Example

Consider an organization with:

```text
On-premises AD
      │
      │ synchronization
      ▼
Microsoft Entra ID
```

Alice has a hybrid identity.

She forgets her password and uses SSPR:

```text
Alice
 ↓
SSPR
 ↓
Identity verification
 ↓
New password
 ↓
Microsoft Entra ID
```

With password writeback configured:

```text
New password
      ↓
Password Writeback
      ↓
On-premises AD
```

This allows the password reset performed through the cloud recovery process to be reflected in the on-premises directory.

---

# Relationship With Previous Concepts

SSPR connects several identity concepts covered previously.

```text
Microsoft Entra User
        ↓
Authentication methods
        ↓
Identity verification
        ↓
SSPR
        ↓
Password reset
```

In a hybrid environment:

```text
SSPR
 ↓
Password reset
 ↓
Password Writeback
 ↓
On-premises AD
```

SSPR is therefore primarily an identity recovery feature rather than an Azure resource authorization mechanism.

It should not be confused with Azure RBAC.

---

# Interview Questions

1. What is Self-Service Password Reset?
2. What problem does SSPR solve?
3. Does SSPR allow users to reset passwords without proving their identity?
4. How does SSPR reduce Help Desk workload?
5. What is the difference between SSPR and MFA?
6. Can SSPR be enabled for selected users?
7. How does SSPR work for cloud identities?
8. Why is password writeback important in hybrid environments?
9. What is password writeback?
10. What is the simplified difference between synchronization and password writeback?
11. In which direction does synchronization normally occur in our simplified hybrid identity model?
12. In which direction does password writeback occur?
13. A hybrid user resets their password using SSPR. How can the new password be reflected in on-premises Active Directory?
14. Is SSPR an Azure RBAC feature?
15. How does identity verification relate to SSPR?

---

# Key Takeaways

- SSPR stands for Self-Service Password Reset.
- SSPR allows users to reset or change passwords without normal Help Desk intervention.
- Users must verify their identity before resetting their password.
- SSPR reduces Help Desk workload.
- SSPR and MFA have different purposes.
- MFA strengthens authentication.
- SSPR provides self-service password recovery/reset.
- SSPR can be targeted according to the organization's configuration.
- Password writeback is important in hybrid identity environments.
- Password writeback writes supported cloud password changes/resets back to on-premises Active Directory.
- A useful simplified model is synchronization = on-prem to cloud and password writeback = cloud to on-prem.
