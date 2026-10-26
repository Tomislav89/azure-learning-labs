# Lesson 12 – Terraform Workspaces

## 1. Objective

The goal of this lesson was to understand how Terraform
workspaces allow multiple independent state snapshots
to exist for the same Terraform configuration.

We created two workspaces:

- dev
- test

We used local Terraform resources so the lab did not
require Azure infrastructure or generate Azure costs.

## 2. What Is a Terraform Workspace?

A Terraform workspace is a named instance of Terraform state.

The same Terraform configuration can be used with
different workspaces.

Each workspace tracks its own managed resources.

For example:

    Terraform Configuration
             |
             +-- Workspace: dev
             |       |
             |       +-- DEV State
             |
             +-- Workspace: test
                     |
                     +-- TEST State

Workspaces separate state, but do not automatically
provide separate credentials, subscriptions or permissions.

IMPORTANT:

Terraform workspaces are not the same as separate
Terraform root configurations.

Both approaches can separate state, but they provide
different levels of configuration and access isolation.

## 3. Our Lab Directory

We created the lab in:

    terraform-modules/
        |
        +-- environments/
                |
                +-- workspaces-lab/
                        |
                        +-- main.tf

The lab used Terraform's built-in terraform_data resource.

This resource does not require the AzureRM provider.

## 4. Terraform Configuration

Our main.tf contained:

    terraform {
      required_version = ">= 1.5.0"
    }

    resource "terraform_data" "environment" {
      input = {
        workspace = terraform.workspace
        name      = "lab-${terraform.workspace}"
      }
    }

    output "current_environment" {
      value = terraform_data.environment.output
    }

Explanation:

required_version:
Defines the minimum supported Terraform CLI version.

terraform_data:
Built-in Terraform resource used for the lab.

input:
Stores the configured values in the resource.

terraform.workspace:
Returns the name of the currently selected workspace.

"lab-${terraform.workspace}":
Uses string interpolation to generate a name
based on the active workspace.

output:
Exposes the resulting values after applying.

## 5. Understanding terraform.workspace

terraform.workspace is a built-in Terraform expression.

It returns the name of the active workspace.

Examples:

When the active workspace is dev:

    terraform.workspace = "dev"

The generated name becomes:

    lab-dev

When the active workspace is test:

    terraform.workspace = "test"

The generated name becomes:

    lab-test

This allows a configuration to adapt its values
based on the selected workspace.

## 6. Initializing the Lab

From the original Terraform project:

    cd ~/workspace/terraform-modules/environments/workspaces-lab

    terraform init

Explanation:

terraform init:
Initializes the working directory and backend.

Because our lab used only terraform_data,
we did not need to configure Azure resources.

The lab used the local Terraform backend.

## 7. Creating Workspaces

We created DEV:

    terraform workspace new dev

Then TEST:

    terraform workspace new test

Explanation:

terraform workspace new:
Creates a new named workspace and selects it.

Each workspace receives its own state.

Terraform automatically switches to the newly
created workspace.

## 8. Listing Workspaces

Command:

    terraform workspace list

This lists available workspaces.

Example:

      default
      dev
    * test

The asterisk indicates the currently selected workspace.

In this example, test is active.

## 9. Switching Between Workspaces

To select DEV:

    terraform workspace select dev

To select TEST:

    terraform workspace select test

Explanation:

terraform workspace select:
Changes the active workspace.

IMPORTANT:

Always verify the selected workspace before
running terraform apply or terraform destroy.

Otherwise, you may change the wrong environment.

## 10. Applying the TEST Workspace

We selected TEST and applied the configuration.

Commands:

    terraform workspace select test

    terraform plan

    terraform apply

Terraform created:

    terraform_data.environment

The output contained:

    workspace = "test"
    name      = "lab-test"

This resource was tracked in the TEST workspace state.

## 11. Applying the DEV Workspace

Next, we selected DEV.

Commands:

    terraform workspace select dev

    terraform plan

    terraform apply

Terraform created a separate resource instance.

The output contained:

    workspace = "dev"
    name      = "lab-dev"

Even though the Terraform configuration was identical,
DEV and TEST used different state snapshots.

## 12. Local State Storage

Our lab used the local backend.

Terraform stored named workspace states under:

    terraform.tfstate.d/

Example structure:

    workspaces-lab/
        |
        +-- main.tf
        |
        +-- terraform.tfstate.d/
                |
                +-- dev/
                |    |
                |    +-- terraform.tfstate
                |
                +-- test/
                     |
                     +-- terraform.tfstate

Each workspace has its own state file.

The default workspace uses the normal local state
location rather than the named workspace directory.

IMPORTANT:

Terraform state files must not be committed to GitHub.

They may contain sensitive infrastructure information.

## 13. Testing State Isolation

After creating resources in both workspaces,
we selected DEV.

Command:

    terraform workspace select dev

We then destroyed the DEV resource:

    terraform destroy

Terraform removed the resource tracked by DEV.

Next, we selected TEST:

    terraform workspace select test

We ran:

    terraform plan

Terraform reported:

    No changes. Your infrastructure matches the configuration.

This demonstrated that destroying resources in
the DEV workspace did not remove the TEST resource.

Each workspace maintained independent state.

## 14. Workspaces with Remote Backends

Workspaces can also be used with remote state backends.

Our main Azure Terraform project used the azurerm backend.

For example, a backend could be configured with:

    terraform {
      backend "azurerm" {
        resource_group_name  = "rg-terraform-state"
        storage_account_name = "sttfstatezivkovic26"
        container_name       = "tfstate"
        key                  = "workspaces.tfstate"
        use_azuread_auth     = true
      }
    }

With the AzureRM backend, the default workspace uses:

    workspaces.tfstate

Named workspaces use separate workspace-specific
blob keys.

For example:

    workspaces.tfstateenv:dev
    workspaces.tfstateenv:test

These are examples of the AzureRM backend's workspace
key convention.

Our actual workspaces lab used the local backend,
not this Azure Storage configuration.

## 15. Workspaces vs Separate Environment Directories

Approach A: Terraform Workspaces

    one configuration
           |
           +-- dev workspace
           |
           +-- test workspace

Advantages:

- Convenient for similar environments.
- Same configuration can be reused.
- Easy workspace switching.

Limitations:

- Same root configuration.
- Easy to select the wrong workspace.
- Does not automatically isolate permissions.
- Environment-specific differences may become complex.

Approach B: Separate Root Configurations

    environments/
        |
        +-- dev/
        |
        +-- test/

Advantages:

- Independent configuration and backend settings.
- Easier separation of deployment permissions.
- More explicit environment boundaries.
- Suitable for different infrastructure requirements.

Limitations:

- Requires additional project organization.
- Shared logic should be moved into reusable modules.

## 16. When Should We Use Workspaces?

Workspaces are useful for:

- Temporary test environments.
- Development sandboxes.
- Similar deployments using one configuration.
- Labs and experimentation.
- Cases where state separation is needed
  without separate root configurations.

For production infrastructure with different
permissions, subscriptions and approval workflows,
separate root configurations and backends are
often easier to manage safely.

Workspaces alone are not a security boundary.

## 17. Important Terraform Commands

Initialize Terraform:

    terraform init

List workspaces:

    terraform workspace list

Show the active workspace:

    terraform workspace show

Create a workspace:

    terraform workspace new dev

Select a workspace:

    terraform workspace select dev

Preview changes:

    terraform plan

Apply configuration:

    terraform apply

Destroy resources in the active workspace:

    terraform destroy

Delete an empty workspace:

    terraform workspace delete dev

IMPORTANT:

A workspace must be empty before normal deletion.

You cannot delete the currently selected workspace.

## 18. Cleanup

We destroyed the DEV lab resource and verified
that the TEST workspace remained independent.

The TEST workspace was also intended for cleanup,
but its final destruction was not confirmed
in the recorded lab output.

To check its current state:

    cd ~/workspace/terraform-modules/environments/workspaces-lab

    terraform workspace select test

    terraform state list

If terraform_data.environment is still tracked,
it can be removed using:

    terraform destroy

This local resource does not generate Azure costs.

Do not run these cleanup commands without first
checking the active directory and workspace.

## 19. Real-World DevOps Usage

Terraform workspaces help engineers understand:

- State isolation.
- Environment-specific configuration.
- Reusing the same infrastructure code.
- Workspace selection during deployment.
- Risks of operating on the wrong environment.
- Differences between workspaces and separate backends.

CI/CD pipelines using workspaces should explicitly
select and verify the intended workspace.

Production deployments should use appropriate
approval and access controls.

## 20. Key Takeaways

1. A Terraform workspace is a separate state instance.
2. The same configuration can be applied in multiple workspaces.
3. terraform.workspace returns the active workspace name.
4. Named local workspaces store state under terraform.tfstate.d.
5. Destroying DEV does not automatically destroy TEST.
6. Workspaces do not provide permission isolation by themselves.
7. Separate root configurations are often preferable
   for environments with different security requirements.
8. Always verify the active workspace before apply or destroy.
