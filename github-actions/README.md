# GitHub Actions – CI/CD Labs

Hands-on GitHub Actions labs focused on CI/CD, Terraform validation,
Git workflows, and future Azure infrastructure automation.

## Learning Goals

- Understand GitHub Actions workflows, events, jobs, and steps
- Execute workflows on GitHub-hosted runners
- Validate Terraform configurations automatically
- Use feature branches and Pull Requests for infrastructure changes
- Validate multiple Terraform configurations with a matrix strategy
- Authenticate to Azure using OpenID Connect (OIDC)
- Implement controlled Terraform deployments

## Repository Structure

The GitHub Actions workflow definitions are stored in:

- `.github/workflows/hello-world.yml`
- `.github/workflows/terraform-ci.yml`

This directory (`github-actions/`) contains the learning documentation.

GitHub discovers workflow definitions inside `.github/workflows/`,
not inside this documentation directory.

---

## Lesson 1 – First GitHub Actions Workflow

### Objective

Create a simple workflow and understand how GitHub Actions executes
commands on a GitHub-hosted runner.

### Workflow

File: `.github/workflows/hello-world.yml`

The workflow supports:

- Automatic execution after a push to `main`
- Manual execution using `workflow_dispatch`

The job runs on a GitHub-hosted Ubuntu runner.

It executes commands that:

- Print a welcome message
- Display operating system information
- Show the current working directory
- Print GitHub environment information

### Core Concepts

**Workflow**

An automated process defined in a YAML file.

**Event / Trigger (`on`)**

Defines when the workflow runs.

Examples:

- `push`: runs when matching changes are pushed
- `pull_request`: runs for matching Pull Request events
- `workflow_dispatch`: allows manual execution

**Job (`jobs`)**

A collection of steps executed on a runner.

**Runner (`runs-on`)**

The machine that executes a job.

For example, `ubuntu-24.04` selects a GitHub-hosted Ubuntu runner.

**Step (`steps`)**

An individual operation inside a job.

**`run`**

Executes shell commands on the runner.

**`uses`**

Invokes an existing GitHub Action.

For example, `actions/checkout@v4` checks out repository content
onto the runner.

### Result

The first Hello World workflow executed successfully on GitHub Actions.

---

## Lesson 2 – Terraform CI and Pull Request Validation

### Objective

Automatically validate Terraform code before merging changes into `main`.

### Workflow

File: `.github/workflows/terraform-ci.yml`

The first version validated only:

`terraform-advanced/environments/workspaces-lab`

This was a deliberately small starting point because the configuration
does not require Azure authentication.

### Terraform Validation Steps

**1. Checkout Repository**

Action: `actions/checkout@v4`

Downloads the appropriate repository revision to the runner.

The runner does not access files directly from the developer's
local computer. Changes must be committed and pushed to GitHub.

**2. Setup Terraform**

Action: `hashicorp/setup-terraform@v3`

Prepares the required Terraform CLI version.

**3. Terraform Format Check**

Command: `terraform fmt -check -recursive .`

Checks Terraform formatting without modifying the files.

**4. Terraform Init**

Command: `terraform init -backend=false -input=false`

Initializes the Terraform working directory without initializing
the configured remote backend and without interactive input.

Provider and module downloads may still occur.

**5. Terraform Validate**

Command: `terraform validate`

Checks Terraform configuration syntax and internal consistency.

This does not deploy infrastructure or guarantee that an Azure
deployment would succeed.

### Pull Request Workflow

The workflow was tested using this process:

1. Create a feature branch from `main`
2. Make changes to the workflow or Terraform configuration
3. Commit the changes locally
4. Push the feature branch to GitHub
5. Open a Pull Request targeting `main`
6. Wait for GitHub Actions validation
7. Review the results
8. Merge the Pull Request after successful checks
9. Switch back to local `main` and pull the merged changes

A Pull Request proposes merging changes into another branch.
Opening a Pull Request does not automatically merge the code.

Branch protection rules can be configured to require successful
checks before merging. Without such rules, a failed check does
not necessarily prevent a merge.

### Understanding `paths`

The Terraform CI workflow contains a Pull Request path filter:

- `terraform-advanced/**`
- `.github/workflows/terraform-ci.yml`

The first pattern matches changes inside the Terraform Advanced
directory and its subdirectories.

The second matches changes to the Terraform CI workflow file itself.

The filter determines whether a Pull Request event triggers
this workflow.

### Understanding `working-directory`

`working-directory` determines where a `run` step executes
its shell command.

For example, setting the working directory to:

`terraform-advanced/environments/workspaces-lab`

means that `terraform validate` executes from that directory.

It is conceptually similar to changing into that directory
with `cd` before running the command.

A job-level `defaults.run.working-directory` applies to its
`run` steps, not to steps using `uses`.

Important distinction:

- `paths` controls which changed files can trigger the workflow
- `working-directory` controls where a shell command executes

### Result

The initial Terraform CI workflow passed its Pull Request checks
and was merged into `main`.

---

## Lesson 3 – Terraform CI Matrix

### Objective

Extend Terraform validation from one configuration to multiple
independent Terraform root directories.

### Why a Matrix?

The original workflow could be triggered by changes anywhere inside
`terraform-advanced/`, but it validated only `workspaces-lab`.

That meant a Pull Request could change a different Terraform
configuration while the CI job checked only `workspaces-lab`.

The matrix strategy addresses this limitation by running validation
for multiple directories.

### Matrix Configuration

The workflow uses `strategy.matrix` with a parameter named `directory`.

The five configurations are:

1. `terraform-advanced/environments/dev-separated/networking`
2. `terraform-advanced/environments/dev-separated/compute`
3. `terraform-advanced/environments/test`
4. `terraform-advanced/environments/lifecycle-lab`
5. `terraform-advanced/environments/workspaces-lab`

GitHub Actions creates a separate job for each matrix entry.

Each job runs:

- Terraform Format Check
- Terraform Init
- Terraform Validate

### Dynamic Working Directory

Each Terraform `run` step uses:

`working-directory: ${{ matrix.directory }}`

GitHub Actions substitutes the directory value for the
corresponding matrix job.

For example:

- Networking job runs in `dev-separated/networking`
- Compute job runs in `dev-separated/compute`
- TEST job runs in `test`

The matrix expression is configured on individual steps rather
than in job-level `defaults.run`.

### `fail-fast: false`

The matrix strategy uses:

`fail-fast: false`

If one matrix job fails, GitHub Actions does not automatically
cancel the other matrix jobs because of that failure.

This allows us to inspect results across all five configurations.

### Result

The matrix workflow was tested through a Pull Request.

All five Terraform validation checks passed successfully.

The Pull Request was merged into `main`, and the local repository
was synchronized with the remote branch.

---

## CI vs CD

**Continuous Integration (CI)**

Automatically checks changes before they are integrated.

Our current Terraform pipeline performs formatting,
initialization, and validation checks.

**Continuous Delivery / Deployment (CD)**

Extends automation toward releasing or deploying changes.

Our current Terraform CI workflow does not run
`terraform plan` or `terraform apply`.

It does not create, update, or destroy Azure resources.

---

## Lab 4 – Azure Authentication with GitHub Actions OIDC

### Objective

Authenticate GitHub Actions to Microsoft Azure securely using
OpenID Connect (OIDC), without storing passwords or client secrets
in GitHub.

### Architecture

GitHub Actions
    |
    | GitHub-issued OIDC token
    v
Microsoft Entra ID
    |
    | Federated Identity Credential validation
    v
App Registration / Service Principal
    |
    | Azure RBAC authorization
    v
Azure Resource Group

### App Registration

Created an application registration named:

`github-actions-terraform-oidc`

The App Registration defines the application identity and contains
the Federated Identity Credential used to establish trust with GitHub.

### Service Principal

Created a Service Principal associated with the App Registration.

The Service Principal represents the application identity in our
Microsoft Entra tenant and is the security principal to which
Azure RBAC roles are assigned.

### Federated Identity Credential

Configured a Federated Identity Credential with:

- Name: `github-main-oidc`
- Issuer: `https://token.actions.githubusercontent.com`
- Audience: `api://AzureADTokenExchange`
- Repository: `Tomislav89/azure-learning-labs`
- Branch: `main`

The subject must match the subject claim in the GitHub-issued
OIDC token exactly.

During this lab, the initial authentication failed with:

`AADSTS700213: No matching federated identity record found`

The GitHub token contained a subject with numeric repository and
owner identifiers, while the original Federated Identity Credential
used repository and owner names only.

We updated the Federated Identity Credential to match the actual
GitHub OIDC subject and successfully reran the workflow.

### Azure RBAC

Created a dedicated Resource Group:

`rg-github-oidc-lab`

Location: `northeurope`

Assigned the Service Principal the `Reader` role at the Resource
Group scope only.

This follows the principle of least privilege:

- The workflow can read resources in the lab Resource Group.
- The workflow cannot modify or delete those resources.
- No subscription-wide Contributor or Owner role was granted.
- The Terraform state Resource Group remains outside this role scope.

### GitHub Actions Workflow

Workflow file:

`.github/workflows/azure-oidc.yml`

Workflow name:

`Azure OIDC Login Test`

Trigger:

`workflow_dispatch`

The workflow is started manually from the GitHub Actions interface.

Required GitHub Actions permissions:

- `id-token: write` – allows the workflow to request an OIDC token.
- `contents: read` – allows read access to repository contents.

The workflow uses `azure/login@v2` with:

- Azure Client ID
- Microsoft Entra Tenant ID
- Azure Subscription ID

These identifiers are not passwords or client secrets.

### Workflow Steps

1. Login to Azure using OIDC.
2. Verify the Azure subscription and tenant.
3. Read the `rg-github-oidc-lab` Resource Group.

### Result

The GitHub Actions workflow completed successfully.

This confirmed that:

- GitHub Actions could obtain an OIDC token.
- Microsoft Entra ID accepted the federated identity.
- The workflow authenticated as the application identity.
- Azure RBAC permitted reading the lab Resource Group.
- No client secret or personal user password was required.

### Authentication vs. Authorization

Authentication answers:

Who are you?

OIDC and Microsoft Entra ID handle authentication.

Authorization answers:

What are you allowed to do?

Azure RBAC handles authorization.

A successful login does not automatically grant permission
to manage Azure resources.

### Key Takeaways

- App Registration defines the application identity.
- Service Principal represents that identity in the tenant.
- Federated Identity Credentials establish OIDC trust.
- OIDC avoids long-lived client secrets in GitHub.
- GitHub OIDC subject claims must match exactly.
- Azure RBAC should use the smallest practical scope.
- `id-token: write` does not grant Azure write permissions.
- `workflow_dispatch` enables manual workflow execution.

---


## Lesson 5 – Terraform Plan and Apply with Azure OIDC and Remote State

### Objective

Deploy and update real Azure infrastructure through GitHub Actions
using Terraform, Microsoft Entra ID OIDC authentication, Azure RBAC,
and an Azure Blob Storage remote backend.

The lab demonstrates:

- Manual Terraform Plan and Apply operations.
- Passwordless authentication through GitHub Actions OIDC.
- Azure RBAC authorization with resource-level scope separation.
- Remote Terraform state and state locking.
- Infrastructure creation and in-place updates.
- Idempotency and post-deployment verification.

### Architecture

The deployment follows this flow:

```text
GitHub Repository (main)
        |
        v
GitHub Actions (workflow_dispatch)
        |
        v
GitHub OIDC Token
        |
        v
Microsoft Entra ID
        |
        v
Azure Service Principal
        |
        +---- Contributor on rg-github-oidc-lab
        |
        +---- Storage Blob Data Contributor on tfstate container
        |
        v
Terraform Init / Validate / Plan / Apply
        |
        +---- Azure Resource Group: rg-github-oidc-lab
        |          |
        |          +---- Storage Account: stgha26lab001
        |
        +---- Azure Storage Account: sttfstatezivkovic26
                   |
                   +---- Container: tfstate
                          |
                          +---- github-actions-deployment.tfstate
```

The Storage Account `stgha26lab001` is the managed infrastructure.

The separate Storage Account `sttfstatezivkovic26` stores Terraform state.
These accounts have different purposes and must not be confused.

### Azure Prerequisites

Deployment Resource Group:

```text
rg-github-oidc-lab
Region: North Europe
```

Remote state backend:

```text
Resource Group: rg-terraform-state
Storage Account: sttfstatezivkovic26
Container: tfstate
Blob key: github-actions-deployment.tfstate
```

Application identity:

```text
App Registration: github-actions-terraform-oidc
Authentication: GitHub Actions OIDC
```

The federated identity credential connects the GitHub repository
and its main branch to the Entra application identity.

The federated credential subject must match the actual GitHub
OIDC token's `sub` claim exactly.

In this lab, GitHub supplied an ID-based subject rather than the
usual repository-name-based format. An initial subject mismatch
caused AADSTS700213. Updating the federated credential to the
actual token subject resolved the issue.

The Service Principal requires two different Azure RBAC permissions:

1. `Contributor` on `rg-github-oidc-lab` to manage the lab infrastructure.
2. `Storage Blob Data Contributor` on the `tfstate` container to read,
   write, and lock the Terraform state blob using Microsoft Entra authentication.

The Service Principal does not need subscription-wide Contributor access.

GitHub's `id-token: write` permission enables OIDC token requests.
It does not itself grant Azure RBAC permissions.

### Repository Structure

```text
.github/workflows/
    terraform-deploy.yml

github-actions/
    terraform-deployment-lab/
        backend.tf
        providers.tf
        main.tf
        .terraform.lock.hcl
```

Terraform-generated `.terraform/`, state files, and temporary plan files
must not be committed to Git.

### Terraform Provider Configuration

File: `github-actions/terraform-deployment-lab/providers.tf`

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "86d4c7aa-bdab-457c-a0f5-f8cfb043e58d"
}
```

The provider connects Terraform to the intended Azure subscription.

The provider version constraint allows compatible AzureRM 4.x versions.
The dependency lock file records the selected provider version.

### Remote State Backend

File: `github-actions/terraform-deployment-lab/backend.tf`

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstatezivkovic26"
    container_name       = "tfstate"
    key                  = "github-actions-deployment.tfstate"

    use_azuread_auth = true
    use_oidc         = true
  }
}
```

`use_azuread_auth = true` enables Microsoft Entra authentication for
Azure Blob Storage instead of relying on storage account access keys.

`use_oidc = true` configures the backend for OIDC authentication
in the GitHub Actions environment.

The `key` selects the state blob within the container. Other Terraform
projects can use different keys, but production environments should
use appropriately isolated state and access boundaries.

Terraform state may contain sensitive data. Do not publish or manually
edit the state file.

### Terraform Infrastructure Configuration

File: `github-actions/terraform-deployment-lab/main.tf`

```hcl
data "azurerm_resource_group" "lab" {
  name = "rg-github-oidc-lab"
}

resource "azurerm_storage_account" "lab" {
  name                     = "stgha26lab001"
  resource_group_name      = data.azurerm_resource_group.lab.name
  location                 = data.azurerm_resource_group.lab.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version                  = "TLS1_2"
  allow_nested_items_to_be_public = false

  tags = {
    environment = "lab"
    managed_by  = "terraform"
    project     = "github-actions"
    owner       = "devops-lab"
  }
}
```

The Resource Group is a `data` source: Terraform reads it but does
not manage its lifecycle.

The Storage Account is a `resource`: Terraform creates, updates,
and can destroy it according to the configuration and execution plan.

The `owner` tag was added during the second deployment exercise.

### GitHub Actions Deployment Workflow

File: `.github/workflows/terraform-deploy.yml`

```yaml
name: Terraform Azure Deployment

on:
  workflow_dispatch:
    inputs:
      operation:
        description: "Terraform operation"
        required: true
        type: choice
        default: plan
        options:
          - plan
          - apply

permissions:
  id-token: write
  contents: read

concurrency:
  group: terraform-deployment-lab
  cancel-in-progress: false

jobs:
  terraform-deployment:
    name: Terraform ${{ inputs.operation }}
    runs-on: ubuntu-latest

    defaults:
      run:
        working-directory: github-actions/terraform-deployment-lab

    env:
      ARM_USE_OIDC: "true"
      ARM_USE_AZUREAD: "true"
      ARM_CLIENT_ID: "e0a670f6-2928-49a3-8532-aff461e897b8"
      ARM_TENANT_ID: "40553eb6-3bdc-49f5-80a3-0b69c3a8cad3"
      ARM_SUBSCRIPTION_ID: "86d4c7aa-bdab-457c-a0f5-f8cfb043e58d"

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Azure Login via OIDC
        uses: azure/login@v2
        with:
          client-id: ${{ env.ARM_CLIENT_ID }}
          tenant-id: ${{ env.ARM_TENANT_ID }}
          subscription-id: ${{ env.ARM_SUBSCRIPTION_ID }}

      - name: Terraform Init
        run: terraform init -input=false

      - name: Terraform Format Check
        run: terraform fmt -check

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        run: terraform plan -input=false -no-color -out=tfplan

      - name: Terraform Apply
        if: inputs.operation == 'apply'
        run: terraform apply -input=false -no-color -auto-approve tfplan
```

### Understanding the Workflow

`workflow_dispatch` allows manual execution from GitHub Actions.

The `operation` input determines whether the workflow performs
only a plan or also executes an apply.

`plan` is the default, reducing the chance of accidentally choosing apply.

`permissions.id-token: write` allows GitHub to request an OIDC token.

`permissions.contents: read` allows repository checkout.

`concurrency` prevents overlapping runs of this workflow from
operating on the same infrastructure simultaneously. Terraform's
backend state lock provides an additional layer of protection.

`terraform init -input=false` initializes the remote backend and
downloads the required provider without interactive prompts.

`terraform fmt -check` checks Terraform formatting.

`terraform validate` validates the Terraform configuration.

`terraform plan -out=tfplan` creates a saved execution plan.

The Apply step runs only when `operation` equals `apply`.
It applies the saved plan generated earlier in the same job.

A separate manually triggered `plan` run is informational.
A later `apply` run generates its own new plan before applying it.
The earlier plan is not reused between workflow runs.

The current lab does not enforce independent human approval
or a reviewed plan artifact. For production, use protected GitHub
Environments, appropriate approval rules, restricted permissions,
and a more formal plan-review process.

### Local Terraform Validation

From the repository root:

```bash
cd github-actions/terraform-deployment-lab

terraform fmt
terraform init -backend=false
terraform validate
```

`-backend=false` permits configuration validation without
connecting to the remote state backend.

For local access to the actual remote state, Azure CLI login
and appropriate Azure RBAC permissions are required.

```bash
az login

terraform init \
  -input=false \
  -backend-config="use_oidc=false"
```

This overrides OIDC for the local initialization so that the
existing Azure CLI identity can be used.

The local `.terraform/` backend initialization is not committed.

### Initial Deployment

After committing and pushing the workflow and Terraform configuration,
open GitHub Actions and select:

```text
Workflow: Terraform Azure Deployment
Branch: main
Operation: plan
```

The initial plan showed:

```text
Plan: 1 to add, 0 to change, 0 to destroy.
```

Then execute a new manual workflow run with `operation: apply`.

The initial deployment completed with:

```text
azurerm_storage_account.lab: Creation complete after 1m20s

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

Verify the Azure resource:

```bash
az storage account show \
  --name stgha26lab001 \
  --resource-group rg-github-oidc-lab \
  --query "{Name:name,Location:location,State:provisioningState,Sku:sku.name}" \
  -o table
```

Observed result:

```text
Name           Location     State      Sku
-------------  -----------  ---------  ------------
stgha26lab001  northeurope  Succeeded  Standard_LRS
```

### Remote State Verification

Check the state blob:

```bash
az storage blob list \
  --account-name sttfstatezivkovic26 \
  --container-name tfstate \
  --auth-mode login \
  --prefix "github-actions-deployment.tfstate" \
  --query "[].{Name:name,Size:properties.contentLength}" \
  -o table
```

The initial state blob was approximately 181 bytes before deployment.

After the Storage Account was created, the blob size was 10663 bytes.

The increased size is consistent with Terraform recording the
managed infrastructure in remote state.

Read the state using Terraform:

```bash
terraform state list
```

Observed result:

```text
data.azurerm_resource_group.lab
azurerm_storage_account.lab
```

The first entry is a read-only data source.

The second entry is the managed Storage Account resource.

### Idempotency Verification

Run:

```bash
terraform plan -input=false -no-color
```

Observed result:

```text
No changes. Your infrastructure matches the configuration.
```

The same result was confirmed through GitHub Actions.

This demonstrates that Terraform recognizes existing infrastructure
and does not propose unnecessary changes when configuration and
actual infrastructure already match.

### Updating Existing Infrastructure

A new tag was added to the Storage Account:

```hcl
owner = "devops-lab"
```

Local validation:

```bash
terraform fmt
terraform plan -input=false -no-color
```

Terraform reported:

```text
# azurerm_storage_account.lab will be updated in-place

+ "owner" = "devops-lab"

Plan: 0 to add, 1 to change, 0 to destroy.
```

`update in-place` means Terraform modifies the existing resource
without replacing it.

The configuration was committed and pushed:

```bash
git add github-actions/terraform-deployment-lab/main.tf
git commit -m "Add owner tag to Terraform managed storage account"
git pull --rebase origin main
git push origin main
```

The change was reviewed in a GitHub Actions `plan` run.

A separate `apply` run completed with:

```text
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```

Verify the new tag in Azure:

```bash
az storage account show \
  --name stgha26lab001 \
  --resource-group rg-github-oidc-lab \
  --query "{Name:name,Tags:tags}" \
  -o json
```

Observed result:

```json
{
  "Name": "stgha26lab001",
  "Tags": {
    "environment": "lab",
    "managed_by": "terraform",
    "owner": "devops-lab",
    "project": "github-actions"
  }
}
```

### State Locking

Terraform displayed:

```text
Acquiring state lock. This may take a few moments...
Releasing state lock. This may take a few moments...
```

State locking prevents concurrent Terraform operations from
modifying the same state at the same time.

The GitHub Actions `concurrency` configuration controls overlapping
workflow runs. State locking protects the backend more broadly,
including when Terraform is also executed locally.

Do not manually remove a state lock unless you have confirmed
that no Terraform operation is still running.

### Troubleshooting

**AADSTS700213 during OIDC login**

The federated identity credential subject does not match
the actual GitHub OIDC token subject.

Check issuer, audience, subject, repository, and branch.
Use the exact subject emitted by GitHub.

**Azure login succeeds but deployment fails with authorization errors**

Authentication and authorization are separate.

Check the Service Principal's Azure RBAC role assignments
at the correct Resource Group or Storage container scope.

**Terraform backend initialization fails**

Check the backend Storage Account, container, blob key,
Azure RBAC permissions, and authentication method.

For local Azure CLI authentication, initialize with
`-backend-config="use_oidc=false"`.

**Terraform reports state locking errors**

Check for another running Terraform operation.

Do not use `-lock=false` to bypass a legitimate concurrent operation.

**GitHub Actions displays an unexpected old plan**

Verify the selected workflow run and its commit SHA.
An older run may use Terraform configuration from an earlier commit.

**Plan succeeds but Apply fails**

Review Azure authorization, resource naming restrictions,
Azure Policy, quotas, and the detailed provider error.

A successful plan does not guarantee that Azure will accept
every change during apply.

### Security and Production Considerations

This is a controlled learning lab, not a production-ready pipeline.

For production environments:

- Use protected GitHub Environments and required approvals.
- Avoid unrestricted direct deployment from arbitrary branches.
- Use separate identities and state boundaries for environments.
- Protect Terraform state because it may contain sensitive values.
- Grant Azure RBAC permissions using least privilege.
- Consider restricting workflow permissions and pinning actions.
- Review execution plans before applying changes.
- Keep infrastructure changes traceable through Git history.
- Avoid storing secrets in Terraform source code or workflow files.
- Consider disabling shared-key access where compatible with requirements.
- Establish monitoring, cost controls, and a safe destroy process.

### Key Takeaways

- GitHub Actions can deploy Azure infrastructure without client secrets.
- OIDC handles authentication; Azure RBAC controls authorization.
- Terraform remote state preserves infrastructure knowledge between runs.
- Terraform state locking protects concurrent state modifications.
- A saved Terraform plan can be applied within the same workflow job.
- Terraform detects when infrastructure already matches configuration.
- Tags can be updated in-place without recreating a Storage Account.
- A successful deployment should be verified independently using Azure CLI.
- Production deployments require stronger approval and isolation controls.

---

## Future Labs

The following topics are planned but are not yet implemented
in the current deployment workflow:

- Protected GitHub Environments and manual approval gates
- Pull request plan reviews and plan artifacts
- Secure handling of credentials and configuration
- Terraform destroy and infrastructure cleanup
- More advanced CI/CD practices for infrastructure projects

## References

- GitHub Actions documentation:
  https://docs.github.com/en/actions

- Workflow syntax:
  https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax

- GitHub Actions Marketplace:
  https://github.com/marketplace?type=actions

- Terraform CLI documentation:
  https://developer.hashicorp.com/terraform/cli
