# Authentication, MFA and Conditional Access

## Overview

Microsoft Entra ID provides authentication and access controls that help protect identities and access to Azure resources.

The main concepts covered in this section are:

```text
Authentication
      ↓
MFA
      ↓
Conditional Access
      ↓
Azure RBAC
```

A useful mental model is:

```text
Authentication
→ Prove who you are

MFA
→ Prove identity using multiple authentication factors

Conditional Access
→ Evaluate conditions and enforce access requirements

Azure RBAC
→ Determine what the identity can do and where
```

---

# Authentication

Authentication is the process of verifying an identity.

It answers the question:

```text
Who are you?

and

Can you prove that identity?
```

Example:

```text
User
 ↓
Microsoft Entra ID
 ↓
Authentication
 ↓
Identity verified
```

Authentication happens before Azure determines what the authenticated identity is authorized to do.

---

# Authentication vs Authorization

Authentication and authorization are different concepts.

## Authentication

```text
Who are you?
Can you prove your identity?
```

Example:

```text
Alice
 ↓
Authentication
 ↓
Identity verified
```

## Authorization

Authorization determines what an authenticated identity is allowed to do.

Example:

```text
Alice
 ↓
Azure RBAC
 ↓
Contributor
 ↓
rg-app-dev
```

Therefore:

```text
Authentication
→ Who are you?

Authorization
→ What are you allowed to do?
```

---

# Authentication Factors

Authentication factors are commonly divided into three categories.

## Something You Know

Information known by the user.

Examples:

```text
Password
PIN
```

## Something You Have

Something possessed by the user.

Examples:

```text
Phone
Hardware security key
```

## Something You Are

Biometric characteristics.

Examples:

```text
Fingerprint
Face
```

A useful memory rule is:

```text
KNOW
HAVE
ARE
```

---

# Multi-Factor Authentication

Multi-Factor Authentication (MFA) requires authentication using multiple factors.

Example:

```text
Password
   ↓
Something you KNOW

        +

Additional authentication factor
   ↓
Something you HAVE / ARE
```

MFA improves security because compromising one authentication factor may not be enough to successfully authenticate.

For example:

```text
Attacker obtains password
        ↓
Password is correct
        ↓
Additional factor required
        ↓
Requirement not satisfied
        ↓
Authentication / access fails
```

MFA should not simply be understood as "multiple steps."

The important concept is the use of multiple authentication factors.

---

# Microsoft Authenticator

Microsoft Authenticator is an authentication application that can be used as part of Microsoft Entra authentication.

It is important to distinguish:

```text
MFA
→ Authentication/security concept

Microsoft Authenticator
→ Authentication application/method
```

Microsoft Authenticator is therefore not the definition of MFA itself.

It is one of the technologies that can participate in authentication and MFA scenarios.

---

# Passwordless Authentication

Passwordless authentication allows users to authenticate without entering a traditional password.

Examples include:

```text
Windows Hello for Business

FIDO2 security keys

Microsoft Authenticator passwordless authentication
```

Passwordless does NOT mean:

```text
No authentication
```

Instead:

```text
No traditional password
        +
Strong authentication mechanism
```

The goal is to reduce dependence on passwords while maintaining strong authentication.

---

# Conditional Access

Conditional Access evaluates conditions and signals associated with an access attempt and applies access controls.

A simple mental model is:

```text
IF
condition

THEN
access control
```

For example:

```text
IF
User accesses a protected application

THEN
Require MFA
```

Another example:

```text
IF
Access violates a defined location policy

THEN
Block access
```

Conditional Access can evaluate different types of context depending on the configured policy.

Examples can include:

```text
User / group

Target resource

Location

Device-related context

Risk-related signals

Authentication requirements
```

---

# Conditional Access and MFA

Conditional Access can be used to require MFA under defined conditions.

Example:

```text
Alice
 ↓
Sign-in attempt
 ↓
Conditional Access evaluation
 ↓
MFA required
 ↓
MFA satisfied?
```

If the requirement is satisfied:

```text
YES
 ↓
Access can continue
```

If it is not satisfied:

```text
NO
 ↓
Access blocked
```

A correct password alone does not bypass a Conditional Access policy requiring MFA.

```text
Correct password
      +
Failed MFA requirement
      ↓
Access denied
```

---

# Conditional Access vs Azure RBAC

Conditional Access and Azure RBAC solve different problems.

## Conditional Access

Conditional Access determines the conditions and requirements under which access can proceed.

```text
Can this access attempt proceed
under the configured conditions?
```

## Azure RBAC

Azure RBAC determines what an identity is authorized to do and at which Azure scope.

```text
WHO
+
WHAT
+
WHERE
```

Example:

```text
Alice
 ↓
Contributor
 ↓
rg-app-dev
```

Therefore:

```text
Conditional Access
→ Under which conditions can access proceed?

Azure RBAC
→ What can the identity do and where?
```

---

# RBAC Does Not Bypass Conditional Access

Consider:

```text
Alice
 ↓
Contributor
 ↓
rg-app-dev
```

Alice has authorization to manage resources in `rg-app-dev`.

However, suppose Conditional Access requires MFA.

```text
Alice
 ↓
Correct password
 ↓
Conditional Access
 ↓
MFA required
 ↓
MFA not satisfied
 ↓
Access blocked
```

The Contributor role does not override the Conditional Access requirement.

RBAC describes Alice's Azure permissions.

It does not guarantee that every sign-in or access attempt will be permitted.

---

# Complete Access Flow

The concepts can be combined into the following simplified flow:

```text
User
 ↓
Sign-in
 ↓
Microsoft Entra ID
 ↓
Authentication
 ↓
Conditional Access evaluation
 ↓
Access requirements satisfied
 ↓
Token / access proceeds
 ↓
Azure Resource Manager / Azure service
 ↓
Azure RBAC
 ↓
Authorized operations
```

A shorter mental model is:

```text
IDENTITY
Who are you?
      ↓
AUTHENTICATION
Prove it
      ↓
CONDITIONAL ACCESS
Are the access requirements satisfied?
      ↓
AUTHORIZATION / RBAC
What can you do and where?
```

---

# Administrator Example

Consider an administrator who needs to manage production resources.

Requirements:

```text
1. Administrator must prove their identity.

2. Strong authentication / MFA is required.

3. Defined access conditions must be satisfied.

4. Administrator should manage only the required Azure resources.
```

The solution can combine multiple controls.

## Authentication

```text
Administrator
      ↓
Microsoft Entra authentication
```

The administrator must prove their identity.

## MFA

Multiple authentication factors provide stronger authentication.

```text
Authentication
      ↓
MFA requirement
```

## Conditional Access

Conditional Access can enforce authentication and access requirements.

```text
IF
Privileged administrator accesses protected resources

THEN
Require appropriate authentication controls
```

## Azure RBAC

Finally, Azure RBAC determines the administrator's permissions and scope.

Instead of unnecessarily granting:

```text
Owner
 ↓
Entire Subscription
```

the administrator may only require:

```text
Contributor
 ↓
rg-production
```

This follows the principle of least privilege.

---

# Authentication and Least Privilege

Strong authentication does not replace least privilege.

For example:

```text
MFA
```

protects authentication, but it does not determine which Azure resources the user should be able to modify.

Similarly:

```text
Azure RBAC
```

controls authorization but does not replace strong authentication.

A secure design combines multiple controls:

```text
Strong Authentication
        +
Conditional Access
        +
Least-Privilege RBAC
```

---

# Example: Developer Access

Requirements:

```text
Developers can modify resources in rg-app-dev.

Developers must satisfy MFA requirements when accessing Azure.
```

Use:

```text
Azure RBAC
      ↓
Contributor
      ↓
rg-app-dev
```

for resource authorization.

Use:

```text
Conditional Access
      ↓
Require MFA
```

for the authentication/access requirement.

Combined:

```text
Developer
    ↓
Authentication
    ↓
Conditional Access
    ↓
MFA requirement satisfied
    ↓
Azure RBAC
    ↓
Contributor
    ↓
rg-app-dev
```

---

# Security Mental Model

The complete security model can be viewed as:

```text
IDENTITY
Who is requesting access?
        ↓
AUTHENTICATION
Can they prove their identity?
        ↓
MFA
Are multiple factors required and satisfied?
        ↓
CONDITIONAL ACCESS
Are the configured access conditions satisfied?
        ↓
AUTHORIZATION
What are they allowed to do?
        ↓
AZURE RBAC
Which actions and which Azure scope?
```

These controls complement each other.

They do not replace one another.

---

# Interview Questions

1. What is authentication?
2. What is the difference between authentication and authorization?
3. What are the three common categories of authentication factors?
4. Give an example of something you know.
5. Give an example of something you have.
6. Give an example of something you are.
7. What is Multi-Factor Authentication?
8. Why is MFA more secure than password-only authentication?
9. Is Microsoft Authenticator the same thing as MFA?
10. What is passwordless authentication?
11. What is Conditional Access?
12. Give an example of a Conditional Access policy.
13. What is the difference between Conditional Access and Azure RBAC?
14. Can a Contributor RBAC assignment bypass a failed Conditional Access requirement?
15. How can Conditional Access and MFA work together?
16. How would you protect an administrator who manages production resources?
17. Why should strong authentication still be combined with least-privilege RBAC?
18. What does KNOW / HAVE / ARE mean?
19. What happens if a user enters the correct password but fails an MFA requirement enforced by Conditional Access?
20. Explain the relationship between Authentication, Conditional Access and Azure RBAC.

---

# Key Takeaways

- Authentication verifies identity.
- Authorization determines what an authenticated identity can do.
- Authentication factors can be categorized as KNOW, HAVE and ARE.
- Password is something you know.
- A phone or hardware security key can represent something you have.
- Fingerprint and face are examples of something you are.
- MFA uses multiple authentication factors.
- Microsoft Authenticator is an authentication application/method, not the definition of MFA.
- Passwordless authentication removes the need to enter a traditional password while still providing strong authentication.
- Conditional Access evaluates access conditions and applies access controls.
- Conditional Access can require MFA.
- A correct password does not bypass an MFA requirement.
- Azure RBAC controls Azure resource authorization.
- Conditional Access and Azure RBAC solve different security problems.
- RBAC does not override Conditional Access.
- Strong authentication should be combined with least-privilege authorization.
