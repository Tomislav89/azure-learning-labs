# Terraform Advanced – Azure Infrastructure Labs

## Project Overview

This project documents practical Terraform Advanced labs focused on Azure infrastructure, reusable modules, multiple environments, remote state management, state migration, workspaces and resource lifecycle management.

The goal was to understand not only how Terraform commands work, but also how infrastructure can be organized and maintained in real-world DevOps environments.

The project includes Terraform configuration files, practical lab examples and detailed technical documentation.

## Technologies

- Terraform
- Microsoft Azure
- AzureRM Provider
- Azure Storage Remote Backend
- Azure CLI
- Linux / WSL2
- Git and GitHub

## Project Structure

    terraform-advanced/
    ├── README.md
    ├── .gitignore
    ├── modules/
    │   ├── networking/
    │   └── compute/
    ├── environments/
    │   ├── test/
    │   ├── dev-separated/
    │   │   ├── networking/
    │   │   └── compute/
    │   ├── workspaces-lab/
    │   └── lifecycle-lab/
    └── docs/
        ├── environments.md
        ├── lesson-11-state-separation.md
        ├── lesson-12-workspaces.md
        ├── lesson-13-lifecycle.md
        ├── locals-functions-dynamic-blocks.md
        ├── providers-backend-state.md
        └── variables-outputs-data-sources.md

## Reusable Terraform Modules

### Networking Module

[Networking Module Documentation](modules/networking/README.md)

Creates an Azure virtual network and multiple subnets using `for_each`.

The module accepts environment-specific configuration through input variables and exposes resource IDs through outputs.

### Compute Module

[Compute Module Documentation](modules/compute/README.md)

Creates an Azure network interface connected to a subnet.

The current module does not deploy an Azure virtual machine.

## Learning Documentation

### Terraform Fundamentals and Advanced Concepts

| Topic | Documentation |
|---|---|
| Providers, Backend and State | [Read documentation](docs/providers-backend-state.md) |
| Variables, Outputs and Data Sources | [Read documentation](docs/variables-outputs-data-sources.md) |
| Locals, Functions and Dynamic Blocks | [Read documentation](docs/locals-functions-dynamic-blocks.md) |
| DEV and TEST Environments | [Read documentation](docs/environments.md) |

### Practical Lessons

| Lesson | Topic | Status | Documentation |
|---|---|---|---|
| 10 | DEV and TEST Environments | Completed | [Read](docs/environments.md) |
| 11 | State Separation and Migration | Completed | [Read](docs/lesson-11-state-separation.md) |
| 12 | Terraform Workspaces | Completed | [Read](docs/lesson-12-workspaces.md) |
| 13 | Lifecycle and Dependencies | Completed | [Read](docs/lesson-13-lifecycle.md) |
| 15 | Final Configuration Review | Completed without Azure redeployment | See validation section |

Earlier Terraform topics are documented by concept rather than assigned individual lesson numbers.

## Environment Separation

The project uses separate root configurations for different infrastructure components.

### TEST

    environments/test/

Remote state:

    test.tfstate

### DEV Networking

    environments/dev-separated/networking/

Remote state:

    dev-networking.tfstate

### DEV Compute

    environments/dev-separated/compute/

Remote state:

    dev-compute.tfstate

The DEV compute configuration reads the application subnet ID from the DEV networking state using `terraform_remote_state`.

This creates a dependency between the configurations.

Deployment order:

    1. DEV networking
    2. DEV compute

Destruction order:

    1. DEV compute
    2. DEV networking

Terraform does not automatically coordinate execution across these independent root configurations.

## Azure Remote State

Terraform state was stored in Azure Storage.

The backend provides centralized state storage and supports state locking.

Separate backend keys were used to isolate infrastructure components.

The original combined DEV state was migrated into separate networking and compute states during Lesson 11.

The migration process, backup procedures and verification steps are documented in:

[Lesson 11 – State Separation and Migration](docs/lesson-11-state-separation.md)

## Workspaces Lab

Location:

    environments/workspaces-lab/

This lab uses `terraform_data` and `terraform.workspace` to demonstrate how Terraform workspaces maintain separate state.

No Azure infrastructure is required for this lab.

[Lesson 12 – Terraform Workspaces](docs/lesson-12-workspaces.md)

## Lifecycle Lab

Location:

    environments/lifecycle-lab/

This lab uses `terraform_data` to demonstrate resource dependencies and lifecycle behavior.

The final configuration includes:

- `depends_on`
- `replace_triggered_by`

Additional lifecycle concepts explored during the lesson include:

- `prevent_destroy`
- `create_before_destroy`
- `ignore_changes`

[Lesson 13 – Lifecycle and Dependencies](docs/lesson-13-lifecycle.md)

## Final Configuration Review

The final stage focused on reviewing and validating the Terraform configurations without deploying new Azure infrastructure.

The following configurations passed `terraform validate`:

- DEV networking
- DEV compute
- TEST
- Workspaces lab
- Lifecycle lab

The project also passed:

    terraform fmt -check -recursive terraform-advanced

Validation confirms Terraform configuration correctness but does not guarantee that a future Azure deployment will succeed.

## Infrastructure Cleanup

Azure lab infrastructure was cleaned up after practical exercises to avoid unnecessary costs.

The remote Azure Storage backend was managed separately.

The repository contains infrastructure configuration and documentation, not deployed infrastructure.

## Security

The repository excludes:

- Terraform state files
- State backups
- Terraform working directories
- Sensitive `.tfvars` files
- Terraform plan files

Provider dependency lock files (`.terraform.lock.hcl`) may be committed to record selected provider versions and checksums.

Never commit credentials, secrets or sensitive Terraform state to GitHub.

## Key Learning Outcomes

Through these labs, I practiced:

1. Designing reusable Terraform modules.
2. Using input variables, outputs and data sources.
3. Creating Azure networking resources with `for_each`.
4. Using locals, functions and dynamic blocks.
5. Managing DEV and TEST configurations.
6. Configuring Azure Storage remote backends.
7. Understanding Terraform state and locking.
8. Separating infrastructure into multiple states.
9. Migrating state with backups and verification.
10. Sharing outputs between independent Terraform configurations.
11. Working with Terraform workspaces.
12. Controlling resource lifecycle and dependencies.
13. Validating infrastructure configurations.
14. Documenting infrastructure as code for GitHub.

## Purpose

This repository is part of my practical Azure Cloud and DevOps learning portfolio.

It demonstrates infrastructure-as-code concepts, Terraform state management and modular Azure infrastructure design.
