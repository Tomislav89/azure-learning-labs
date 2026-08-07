# Azure Resource Manager

## Overview

Azure Resource Manager (ARM) is the management layer and control plane used to deploy, manage, and organize Azure resources.

Different management tools ultimately interact with Azure through Azure management APIs.

Examples include:

```text
Azure Portal ───────┐
Azure CLI ──────────┤
Bicep ──────────────┼──> Azure Resource Manager
Terraform ──────────┤
REST API ───────────┘
```

## Responsibilities

Azure Resource Manager is responsible for management operations including:

- Authentication integration
- Authorization
- Request validation
- Deployment coordination
- Dependency handling
- Applying management controls at Azure scopes

ARM acts as an orchestrator.

It does not directly implement every Azure service.

## Deployment Flow

A simplified deployment request:

```text
User / Automation
       │
       ▼
Azure management tool
       │
       ▼
Azure Resource Manager
       │
       ├── Authentication
       ├── Authorization
       ├── Validation
       └── Deployment coordination
       │
       ▼
Azure Resource Provider
       │
       ▼
Azure Resource
```

## Control Plane

The control plane is used to manage Azure resources.

Examples:

- Create a Virtual Machine
- Delete a Virtual Machine
- Resize a Virtual Machine
- Create a Storage Account
- Configure resource networking
- Assign RBAC permissions

These operations change the Azure resource configuration.

## Data Plane

The data plane is used to interact with the functionality or data exposed by a resource.

Storage Account examples:

```text
Control Plane:
Create Storage Account
Configure networking
Delete Storage Account

Data Plane:
Upload blob
Download blob
Delete blob
```

Virtual Machine example:

```text
Control Plane:
Create VM
Resize VM
Delete VM

Workload / guest access:
SSH into VM
Modify files
Run applications
```

Control-plane authorization and data-plane authorization can use different permission models depending on the Azure service.

## Idempotency

Idempotency means that repeatedly applying the same desired configuration should result in the same final state rather than creating unnecessary duplicates.

This concept is fundamental to Infrastructure as Code.

For example, if infrastructure already matches the desired configuration, another deployment should not recreate everything unnecessarily.

## ARM and Terraform

Terraform does not directly create Azure infrastructure.

A simplified flow is:

```text
Terraform configuration
        │
        ▼
Terraform Azure Provider
        │
        ▼
Azure management APIs / ARM
        │
        ▼
Azure Resource Provider
        │
        ▼
Azure Resource
```

After Azure reports the resulting resource information, Terraform records the relevant state information in its Terraform state.

ARM does not manage the Terraform state file.

## Practical Note: Azure CLI Authentication

Azure CLI commands that interact with Azure management APIs require valid authentication.

An expired authentication session may produce errors such as:

```text
AADSTS700082:
The refresh token has expired due to inactivity.
```

This is an authentication issue rather than a Resource Provider deployment problem.

## Interview Questions

1. What is Azure Resource Manager?
2. Why do Azure Portal, Azure CLI, Bicep, and Terraform ultimately interact with Azure management APIs?
3. What is the difference between the control plane and data plane?
4. What does idempotency mean?
5. Does ARM directly create Virtual Machines?
6. What happens when Terraform deploys an Azure resource?

## Key Takeaways

- ARM is Azure's management layer and control plane.
- ARM coordinates resource management requests.
- Control-plane operations manage Azure resources.
- Data-plane operations interact with the functionality or data of a service.
- Idempotency is fundamental to Infrastructure as Code.
- Terraform manages Terraform state; ARM does not.
