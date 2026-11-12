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

## Lesson 6 – GitHub Actions Environments & Manual Approval Gates

### Objective

Separate Terraform planning from infrastructure deployment and require a human approval before applying changes to the Azure development environment.

The lesson builds on Lesson 5's Azure OIDC authentication and Azure Blob Storage remote state. The final workflow uses two GitHub Actions jobs, transfers an immutable saved Terraform plan as a short-lived artifact, and uses the GitHub Environment `dev` to gate the apply job.

Learning outcomes:

- Distinguish `workflow_dispatch` inputs, job conditions, job dependencies, and environment protection rules.
- Understand why separate jobs need an artifact to transfer a saved Terraform plan.
- Configure a required reviewer for the `dev` environment and restrict deployment branches to `main`.
- Understand how the GitHub OIDC token subject changes for a job using an environment.
- Verify that the plan-only and plan-plus-apply paths behave differently.
- Troubleshoot a failed Azure login caused by an incorrect subscription ID.

### Architecture and Execution Flow

```text
Developer manually starts workflow on main
                 |
                 v
       workflow_dispatch input
         operation: plan/apply
                 |
                 v
      terraform-plan job
      - checkout repository
      - configure Terraform
      - authenticate to Azure via OIDC
      - terraform init / fmt / validate
      - terraform plan -out=tfplan
                 |
           operation == apply?
           /             \
         no              yes
         |                |
      finish       upload tfplan artifact
                          |
                          v
                terraform-apply job
                needs: terraform-plan
                environment: dev
                          |
                          v
                GitHub required reviewer
                manual approval
                          |
                          v
                separate Ubuntu runner
                - checkout / setup
                - Azure OIDC login
                - terraform init
                - download tfplan
                - terraform apply tfplan
                          |
                          v
                  Azure resources
                Azure Blob remote state
```

**Important:** The environment approval occurs *before the apply job starts*. GitHub holds the job pending until the environment protection rule is satisfied. The plan job is not environment-gated in this lab.

### GitHub Environment Configuration

In the repository, navigate to **Settings → Environments → New environment** and create `dev`.

For this lab, configure:

| Setting | Lab value | Purpose |
| --- | --- | --- |
| Environment name | `dev` | Identifies the deployment target and protection boundary |
| Required reviewer | Repository owner (`Tomislav89`) | Requires an explicit approval before the apply job begins |
| Prevent self-review | Disabled for this learning lab | Allows the workflow initiator to approve their own deployment |
| Deployment branches/tags | Selected branches: `main` | Limits which Git refs may deploy to this environment |
| Admin bypass | Enabled for the lab | Allows permitted administrators to bypass protection if necessary |

These settings are appropriate for testing the mechanism, **not** for a production separation-of-duties model. Production should normally prevent self-approval, limit bypass privileges, and use independent reviewers. Environment protection availability depends on repository visibility and GitHub plan; in this lab the reviewer gate was verified in a real workflow run.

Adding `environment: dev` to a job is necessary to associate it with this environment, but **does not by itself guarantee approval**. Approval comes from the environment's configured protection rules and their availability for the repository.

### OIDC Federation for Branch and Environment Jobs

GitHub Actions requests a short-lived OIDC token from GitHub. Microsoft Entra ID validates its issuer, audience, and subject against a federated identity credential on the Azure App Registration. Azure RBAC then determines what the authenticated service principal is authorized to do.

App Registration: `github-actions-terraform-oidc`.

Two federated credentials are configured:

| Credential | Subject scope | Used by |
| --- | --- | --- |
| `github-main-oidc` | GitHub repository, `refs/heads/main` | `terraform-plan` (no environment) |
| `github-dev-oidc` | GitHub repository, `environment:dev` | `terraform-apply` (environment `dev`) |

The issuer is `https://token.actions.githubusercontent.com`, and the audience is `api://AzureADTokenExchange`.

The full GitHub OIDC subject is generated from the repository's GitHub identity and context. In this lab the observed subjects were:

```text
repo:Tomislav89@15340421/azure-learning-labs@1325714503:ref:refs/heads/main
repo:Tomislav89@15340421/azure-learning-labs@1325714503:environment:dev
```

These strings must match the actual federated credential configuration in Entra ID. Do not assume a branch-based credential also matches an environment-based token. The credential *names* are descriptive labels; the YAML does not reference them. Azure matches token claims to the configured federated credential.

Both jobs need `id-token: write` because each performs its own OIDC login on a separate runner. This permission allows requesting a GitHub OIDC token; it does **not** itself grant Azure permissions.

For this lab the service principal has Contributor on `rg-github-oidc-lab` and Storage Blob Data Contributor on the `tfstate` container in `sttfstatezivkovic26` (resource group `rg-terraform-state`). The state key is `github-actions-deployment.tfstate`.

### Complete GitHub Actions Workflow

Source file: `.github/workflows/terraform-deploy.yml`.

The following is a snapshot of the workflow at the end of Lesson 6. The actual repository file is the authoritative version if the workflow is changed later.

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
  contents: read

concurrency:
  group: terraform-deployment-lab
  cancel-in-progress: false

jobs:
  terraform-plan:
    name: Terraform Plan
    runs-on: ubuntu-latest

    permissions:
      contents: read
      id-token: write

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

      - name: Upload Terraform Plan
        if: inputs.operation == 'apply'
        uses: actions/upload-artifact@v4
        with:
          name: terraform-plan
          path: github-actions/terraform-deployment-lab/tfplan
          retention-days: 1
          if-no-files-found: error

  terraform-apply:
    name: Terraform Apply
    if: inputs.operation == 'apply'
    needs: terraform-plan
    runs-on: ubuntu-latest

    environment:
      name: dev

    permissions:
      contents: read
      id-token: write

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

      - name: Download Terraform Plan
        uses: actions/download-artifact@v4
        with:
          name: terraform-plan
          path: github-actions/terraform-deployment-lab

      - name: Terraform Apply
        run: terraform apply -input=false -no-color tfplan
```

### Understanding the Workflow

**Manual operation selection:** `workflow_dispatch` provides an `operation` choice (`plan` or `apply`), with `plan` as the default. A manual run is launched from the GitHub Actions UI against the chosen branch and commit.

**Top-level permissions:** `contents: read` is the conservative default. Each job explicitly adds `id-token: write` because Azure OIDC authentication requires it.

**Concurrency:** `group: terraform-deployment-lab` prevents overlapping runs in the same group. `cancel-in-progress: false` avoids cancelling a deployment already underway. GitHub concurrency is not a substitute for Terraform backend state locking.

**Working directory:** Both jobs use `defaults.run.working-directory: github-actions/terraform-deployment-lab`. This affects shell `run:` steps; action inputs such as artifact `path:` are interpreted relative to the GitHub workspace, so the full repository-relative path is specified for upload and download.

**Azure authentication:** `azure/login@v2` uses the client, tenant, and subscription identifiers supplied from job environment variables. `ARM_USE_OIDC=true` and `ARM_USE_AZUREAD=true` support Terraform's OIDC and Azure AD authentication, including remote backend access. No long-lived Azure client secret is stored in the workflow.

**Plan validation:** `terraform init -input=false` initializes providers and the remote backend; `terraform fmt -check` checks formatting; `terraform validate` validates the configuration; `terraform plan -input=false -no-color -out=tfplan` saves a binary execution plan.

**Conditional upload:** `if: inputs.operation == 'apply'` uploads the saved `tfplan` only for an apply operation. The artifact is named `terraform-plan`; `retention-days: 1` minimizes how long it is retained; `if-no-files-found: error` fails the step if the expected plan is missing.

**Job dependency and condition:** The apply job uses both `needs: terraform-plan` and `if: inputs.operation == 'apply'`. The dependency ensures the plan job succeeds first; the condition ensures a plan-only run skips the apply job.

**Environment approval:** `environment: name: dev` associates the apply job with GitHub's protected `dev` environment. With the configured required reviewer, GitHub pauses execution until approval. The approval controls job start, not an individual Terraform command inside an already-running job.

**Separate runner:** Jobs do not share a working directory or filesystem. The apply job must check out the repository, install Terraform, log in to Azure, and initialize the backend again.

**Download path:** `actions/download-artifact@v4` downloads artifact `terraform-plan` into the directory `github-actions/terraform-deployment-lab`. Because the artifact contains a file named `tfplan`, the result is `github-actions/terraform-deployment-lab/tfplan`. The `path` input identifies the **destination directory**, not the filename to create.

**Apply saved plan:** `terraform apply -input=false -no-color tfplan` applies the exact saved plan produced by the successful plan job, rather than recalculating a fresh plan in the apply job. The plan is bound to the state and provider/configuration context in which it was generated; it may fail if state or external conditions have changed in the meantime.

### Plan Artifacts: Security and Lifecycle

The saved plan file is binary Terraform output, not a human-readable approval report. It may contain sensitive configuration or values. Limit artifact access and retention, and do not publish plan artifacts openly.

```text
Plan runner:
  github-actions/terraform-deployment-lab/tfplan
           |
           | actions/upload-artifact@v4
           v
  GitHub artifact: terraform-plan
           |
           | actions/download-artifact@v4
           v
Apply runner:
  github-actions/terraform-deployment-lab/tfplan
```

In a production workflow, reviewers should be able to inspect an appropriately redacted human-readable plan summary before approval. A binary artifact alone does not provide that review experience. Protect the workflow and Terraform files from unauthorized changes and consider artifact integrity and access controls.

### Manual Testing and Expected Behavior

**Test 1 – Plan only**

1. Open **Actions → Terraform Azure Deployment → Run workflow**.
2. Select branch `main` and `operation: plan`.
3. Start a **new** run.
4. Verify `Terraform Plan` succeeds and `Terraform Apply` is skipped.
5. Confirm the workflow does not request an environment approval for this path.

**Test 2 – Apply with approval**

1. Start a **new** run on branch `main` with `operation: apply`.
2. Verify the `Terraform Plan` job completes successfully and uploads the artifact.
3. Verify GitHub shows a pending deployment / **Review deployments** prompt for `dev`.
4. Review the deployment and click **Approve and deploy**.
5. Verify `Terraform Apply` starts only after approval and completes successfully.
6. Open the `Terraform Apply` step and inspect the final result.

The successful final test used commit `0d27ba5` and produced:

```text
Run terraform apply -input=false -no-color tfplan
Acquiring state lock. This may take a few moments...
Releasing state lock. This may take a few moments...
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

This verifies that the infrastructure already matched the desired Terraform configuration: no new resources, changes, or deletions were needed. It also shows Terraform acquired and released the backend state lock. The user confirmed the manual reviewer approval was required before the apply job ran.

Successful run: https://github.com/Tomislav89/azure-learning-labs/actions/runs/41436303365/job/125250973366

### Troubleshooting: Incorrect Azure Subscription ID

During the first apply test, `Terraform Plan` succeeded but `Terraform Apply` failed in `Azure Login via OIDC`. The apply job contained a typo in `ARM_SUBSCRIPTION_ID`; the plan job contained the correct value.

The error reported that the subscription did not exist in `AzureCloud`. This did **not** establish that the subscription was missing or that the service principal lacked RBAC. Comparing the workflow's two job environments revealed the mismatch.

The fix was to set both job values to the same correct Azure subscription ID. The following commands were used to verify the change:

```bash
grep -n 'ARM_SUBSCRIPTION_ID:' .github/workflows/terraform-deploy.yml
git diff --check
```

Expected outcome: two matching `ARM_SUBSCRIPTION_ID` entries and no whitespace errors from `git diff --check`.

Commit and push workflow changes using the normal repository process:

```bash
git status
git add .github/workflows/terraform-deploy.yml
git commit -m "Fix Azure subscription ID in Terraform Apply job"
git pull --rebase origin main
git push origin main
```

The correction was committed as `0d27ba5` and the local `main` and `origin/main` were confirmed synchronized:

```bash
git status -sb
git log -1 --oneline
git rev-parse origin/main
```

**Critical troubleshooting lesson:** A GitHub Actions **Re-run all jobs** operation reruns the original run's commit. It does not pick up YAML fixes from a newer commit. After changing the workflow, start a **new** `workflow_dispatch` run on `main` and verify its commit SHA before diagnosing further.

### Security and Production Considerations

This exercise validates an approval gate, but the design is a learning lab rather than a fully hardened production deployment system.

- Disable self-approval and use independent reviewers for production environments.
- Restrict deployment branches and protect `main` with appropriate branch/ruleset policies.
- Minimize admin bypass permissions and record approval decisions.
- Use distinct Azure identities and least-privilege RBAC for planning and applying where practical.
- Understand that the plan job currently has Azure Contributor permissions; the GitHub approval gate is **not** an Azure RBAC security boundary.
- Protect remote Terraform state and restrict access to plan artifacts; both can contain sensitive values.
- Add a redacted plan summary to pull request or approval workflows so reviewers can evaluate proposed changes.
- Consider pinning third-party GitHub Actions to immutable commit SHAs.
- Ensure the plan artifact corresponds to the expected commit and workflow run; avoid untrusted artifact substitution.
- Keep state locking, concurrency controls, and deployment audit trails.
- Never commit credentials, client secrets, Terraform state files, or sensitive `.tfvars` files.
- Define recovery, rollback, and destroy procedures before using this pattern for critical infrastructure.

### Key Takeaways

- `terraform-plan` and `terraform-apply` are independent jobs with separate runners.
- `needs:` enforces ordering; `if:` controls whether the apply job runs.
- A saved `tfplan` is transferred with GitHub artifact upload and download actions.
- GitHub Environment `dev` can require approval before the apply job starts.
- An environment-scoped OIDC token has a different subject from a branch-scoped token.
- Azure OIDC authentication and Azure RBAC authorization are distinct concerns.
- `terraform apply tfplan` applies the saved plan without recalculating it.
- The final run verified manual approval, successful Azure login, state locking, and zero infrastructure drift.
- After changing workflow YAML, start a new run from the updated commit rather than rerunning an old run.

---

## Lesson 7 – Terraform Pull Request Validation and Plan

### Goal

Automatically validate Terraform code and generate a Terraform Plan
when a Pull Request targets the `main` branch.

This lesson extends our existing GitHub Actions deployment lab with
a separate Pull Request pipeline.

The key architectural principle is separation of responsibilities:

- Pull Request pipeline: validate and review proposed infrastructure changes.
- Deployment pipeline: execute approved infrastructure changes.

The PR pipeline does not execute `terraform apply`.

### Architecture

```text
Developer creates feature branch
              |
              v
Developer opens Pull Request to main
              |
              v
GitHub Actions: terraform-pr.yml
              |
              v
Terraform Format Check
              |
              v
GitHub OIDC Token
              |
              v
Microsoft Entra ID
              |
              v
PR Service Principal
              |
              v
Azure Login
              |
              v
Terraform Init (Azure Remote Backend)
              |
              v
Terraform Validate
              |
              v
Terraform Plan
              |
              v
Review results before merge
```

### Part 1 – Initial PR Validation

We first created:

`.github/workflows/terraform-pr.yml`

The initial workflow executed:

```bash
terraform fmt -check -recursive
terraform init -backend=false -input=false
terraform validate
```

At this stage, no Azure authentication was required.

`terraform fmt -check -recursive` verifies Terraform formatting
without modifying the files.

`terraform init -backend=false` initializes Terraform without
connecting to the configured Azure remote backend.

`terraform validate` verifies the syntax and internal consistency
of the Terraform configuration.

This initial pipeline was tested through a Pull Request and
successfully merged into `main`.

### Part 2 – Why Terraform Plan Needs Azure Access

Unlike basic validation, our Terraform Plan uses real Azure
infrastructure and an existing Terraform remote state.

Terraform needs to:

1. Authenticate to Azure.
2. Access the configured remote state.
3. Read relevant Azure resource information.
4. Calculate the proposed infrastructure changes.

Therefore, we extended the workflow with Azure OIDC authentication.

### Part 3 – Separate App Registration for PR Validation

We created a new Microsoft Entra App Registration:

`github-actions-terraform-pr-oidc`

Application (Client) ID:

`d3ebe1d4-46cd-49b4-961c-877c9533561b`

App Registration Object ID:

`88bf4aa9-dac7-4e52-882c-752cabf26493`

Enterprise Application / Service Principal Object ID:

`739cdef8-a47a-4650-be24-913c906c6799`

These identifiers have different purposes:

- Client ID identifies the application during authentication.
- App Registration Object ID identifies the application object.
- Service Principal Object ID identifies the enterprise application
  instance to which Azure RBAC permissions are assigned.

The App Registration defines the application identity.

The Service Principal represents that identity in the Azure tenant
and receives Azure RBAC role assignments.

We deliberately created a separate identity rather than reusing
the deployment Service Principal.

This follows the Least Privilege principle.

### Part 4 – Federated Credential for Pull Requests

In the App Registration, we created a Federated Credential
for GitHub Actions.

Configuration:

```text
Issuer:
https://token.actions.githubusercontent.com

Audience:
api://AzureADTokenExchange

Entity type:
Pull request

Credential name:
github-pr-oidc
```

The federated credential allows Microsoft Entra ID to trust
matching GitHub OIDC tokens.

The token contains claims describing the GitHub repository
and the workflow execution context.

Microsoft Entra ID verifies these claims against the configured
Federated Credential.

If validation succeeds, GitHub Actions can obtain an Azure
access token without storing an Azure Client Secret.

Important distinction:

- Authentication answers: Who is this workflow?
- Authorization answers: What is this identity allowed to do?

Federated Credentials handle the trust relationship.

Azure RBAC controls permissions on Azure resources.

### Part 5 – Azure RBAC Permissions

We assigned two Azure RBAC roles to the new PR Service Principal.

Role 1:

```text
Role:
Reader

Scope:
rg-github-oidc-lab
```

This allows the identity to read Azure resource configuration
in the deployment Resource Group.

Role 2:

```text
Role:
Storage Blob Data Reader

Scope:
Storage Account: sttfstatezivkovic26
Container: tfstate
```

This allows the identity to read blobs in the Terraform
state container.

The identity does not have Contributor permissions on the
deployment Resource Group or Storage Blob Data Contributor
permissions on the state container.

We verified the assignments with Azure CLI:

```bash
az role assignment list   --assignee 739cdef8-a47a-4650-be24-913c906c6799   --all   --query "[].{role:roleDefinitionName,scope:scope}"   -o table
```

The output confirmed:

```text
Reader
Storage Blob Data Reader
```

Security note:

Terraform state may contain sensitive information.

Storage Blob Data Reader provides read access to the permitted
blobs, so this role must not be treated as harmless.

For production, consider separate state containers, stricter
access boundaries, and trusted PR execution paths.

### Part 6 – GitHub Actions Permissions

Our workflow contains:

```yaml
permissions:
  contents: read
```

The job also declares:

```yaml
permissions:
  contents: read
  id-token: write
```

`contents: read` allows the workflow to read repository contents,
including the Terraform configuration.

`id-token: write` allows the job to request a GitHub OIDC token.

It does not grant permission to modify Azure resources.

Azure resource permissions come from Azure RBAC assignments
on the authenticated Service Principal.

### Part 7 – Terraform Backend Configuration

File:

`github-actions/terraform-deployment-lab/backend.tf`

Configuration:

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

`use_azuread_auth = true` enables Microsoft Entra authentication
for Azure Blob Storage data access.

`use_oidc = true` enables OIDC authentication for the backend.

The state file is stored remotely in Azure Storage.

Terraform state describes the infrastructure Terraform currently
manages, including resource identities and attributes.

The backend and the AzureRM provider have separate authentication
requirements, even though both use the same Azure identity
in this lab.

### Part 8 – GitHub Actions Workflow

File:

`.github/workflows/terraform-pr.yml`

```yaml
name: Terraform Pull Request Validation

on:
  pull_request:
    branches:
      - main
    paths:
      - "github-actions/terraform-deployment-lab/**"
      - ".github/workflows/terraform-pr.yml"

permissions:
  contents: read

jobs:
  terraform-pr-validation:
    name: Terraform PR Validation
    runs-on: ubuntu-latest
    if: github.event.pull_request.head.repo.full_name == github.repository

    permissions:
      contents: read
      id-token: write

    defaults:
      run:
        working-directory: github-actions/terraform-deployment-lab

    env:
      ARM_USE_OIDC: "true"
      ARM_USE_AZUREAD: "true"
      ARM_CLIENT_ID: "d3ebe1d4-46cd-49b4-961c-877c9533561b"
      ARM_TENANT_ID: "40553eb6-3bdc-49f5-80a3-0b69c3a8cad3"
      ARM_SUBSCRIPTION_ID: "86d4c7aa-bdab-457c-a0f5-f8cfb043e58d"

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Format Check
        run: terraform fmt -check -recursive

      - name: Azure Login via OIDC
        uses: azure/login@v2
        with:
          client-id: ${{ env.ARM_CLIENT_ID }}
          tenant-id: ${{ env.ARM_TENANT_ID }}
          subscription-id: ${{ env.ARM_SUBSCRIPTION_ID }}

      - name: Terraform Init
        run: terraform init -input=false

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        run: terraform plan -input=false -no-color -lock=false -refresh=false
```

### Part 9 – Workflow Trigger and Path Filtering

The workflow runs when a Pull Request targets `main` and
contains changes matching the configured paths.

```yaml
on:
  pull_request:
    branches:
      - main
```

This specifies the destination branch of the Pull Request.

```yaml
paths:
  - "github-actions/terraform-deployment-lab/**"
  - ".github/workflows/terraform-pr.yml"
```

This limits execution to relevant Terraform project changes
or modifications to the PR workflow itself.

A PR changing unrelated files may not trigger this workflow.

When using required GitHub status checks, path filtering
must be designed carefully because skipped workflows can
leave required checks pending.

### Part 10 – Restricting Fork Pull Requests

The job contains:

```yaml
if: github.event.pull_request.head.repo.full_name == github.repository
```

This checks whether the source repository of the Pull Request
is the same repository running the workflow.

Pull Requests from external forks will not execute this job.

This is an additional safety measure for our controlled lab.

However, this condition alone does not protect against
untrusted changes made on branches inside the same repository.

A production design should enforce repository permissions,
branch protection, code review, and trusted workflow boundaries.

### Part 11 – Azure Login via OIDC

```yaml
- name: Azure Login via OIDC
  uses: azure/login@v2
  with:
    client-id: ${{ env.ARM_CLIENT_ID }}
    tenant-id: ${{ env.ARM_TENANT_ID }}
    subscription-id: ${{ env.ARM_SUBSCRIPTION_ID }}
```

The Azure Login action requests a GitHub OIDC token and
exchanges it with Microsoft Entra ID.

The App Registration's Federated Credential determines
whether the GitHub token is trusted.

If authentication succeeds, the workflow receives an Azure
access token for the configured identity.

No Client Secret is stored in the repository.

### Part 12 – Terraform Initialization and Validation

```bash
terraform init -input=false
terraform validate
```

Unlike the initial validation-only workflow, this initialization
uses the configured Azure remote backend.

`-input=false` disables interactive prompts, which is important
for unattended CI pipelines.

`terraform validate` checks Terraform configuration validity.

Successful initialization also verifies that the configured
identity can access the backend in this lab.

### Part 13 – Terraform Plan

Our final PR pipeline executes:

```bash
terraform plan -input=false -no-color -lock=false -refresh=false
```

Parameter explanations:

- `-input=false`: disables interactive input.
- `-no-color`: removes terminal color escape sequences from CI logs.
- `-lock=false`: disables Terraform state locking.
- `-refresh=false`: skips refreshing managed resource state from
  the remote infrastructure before planning.

Why did we use these options?

The PR Service Principal has Storage Blob Data Reader permissions.

Normal Azure Blob state locking requires operations that
a read-only blob identity cannot perform.

Disabling state locking allows us to test this restricted
read-only workflow.

Disabling refresh reduces reliance on reading live managed
resource state during this controlled lab.

Important limitations:

- The plan may not detect infrastructure drift.
- The state can change concurrently while the plan runs.
- The plan may become outdated before deployment.
- A plan can still expose sensitive Terraform information.
- A plan is not a security approval or a substitute for review.

These settings are suitable only for this specific
learning experiment, not a production deployment design.

### Part 14 – Git Workflow and Pull Request Test

We created the feature branch:

```bash
git checkout -b feature/terraform-pr-plan
```

After modifying the workflow:

```bash
git status -sb
git diff --check

git add .github/workflows/terraform-pr.yml

git commit -m "Add Azure OIDC authentication and Terraform plan to PR workflow"

git push -u origin feature/terraform-pr-plan
```

We opened a Pull Request targeting `main`.

GitHub Actions automatically started the Terraform PR
Validation workflow.

The workflow completed successfully, including:

- Terraform Format Check
- Azure Login via OIDC
- Terraform Init
- Terraform Validate
- Terraform Plan

The successful run demonstrated that the configured
read-only Azure identity was sufficient for this specific
Terraform Plan execution.

After verifying the successful checks, we merged the PR.

We synchronized the local repository:

```bash
git checkout main
git pull --rebase origin main
git status -sb
```

The merge updated `main` to commit:

`3645384`

### Part 15 – PR Pipeline vs Deployment Pipeline

| Capability | PR Pipeline | Deployment Pipeline |
|---|---|---|
| Trigger | Pull Request | Manual workflow_dispatch |
| Purpose | Validation and proposed changes | Deployment |
| Azure identity | PR Service Principal | Deployment Service Principal |
| Resource permissions | Reader | Contributor at lab Resource Group |
| State permissions | Blob Data Reader | Blob Data Contributor |
| Terraform validate | Yes | Separate workflow design |
| Terraform plan | Yes | Yes |
| Terraform apply | No | Yes, after approval |
| Manual approval | Not configured | GitHub Environment dev |
| State locking | Disabled in PR lab | Enabled for deployment |

The most important principle:

PR pipelines should not automatically receive the same
deployment privileges as production apply pipelines.

### Part 16 – Troubleshooting

#### Azure Login fails

Check:

- Client ID, Tenant ID, and Subscription ID.
- `id-token: write` permission.
- App Registration Federated Credential.
- Pull Request subject configuration.
- Repository and organization identifiers.

A successful GitHub OIDC token request does not guarantee
that Microsoft Entra ID will accept the token.

#### Terraform Init fails with authorization errors

Check:

- Storage Account and container names.
- Terraform backend key.
- Storage Blob Data Reader assignment.
- Scope of the RBAC assignment.
- Whether the backend requires additional operations.

Do not immediately grant Contributor permissions.

Investigate the exact failed operation first.

#### Terraform Plan fails

Check:

- Terraform configuration and provider settings.
- Azure Reader permissions.
- Backend access.
- Whether state locking is enabled.
- Whether refresh is enabled.
- Any data sources requiring additional permissions.

#### Workflow does not start

Check:

- The PR targets `main`.
- At least one changed file matches the `paths` filter.
- The workflow YAML is valid.
- The PR originates from the expected repository.

#### PR job is skipped

The repository restriction may be responsible:

```yaml
if: github.event.pull_request.head.repo.full_name == github.repository
```

Fork-based PRs are intentionally skipped by this job.

### Part 17 – Production Improvements

For a real production CI/CD environment:

1. Use trusted workflow execution and protected branches.
2. Prevent untrusted PR code from obtaining privileged cloud access.
3. Use dedicated identities and narrowly scoped Azure permissions.
4. Keep Terraform state locking enabled where correctness matters.
5. Refresh live infrastructure state when preparing deployment plans.
6. Protect state files and plan artifacts as sensitive information.
7. Pin third-party GitHub Actions to reviewed commit SHAs.
8. Consider a sanitized plan summary for PR review.
9. Require approval before infrastructure deployment.
10. Ensure the approved plan corresponds to the expected commit.
11. Configure CI concurrency and state ownership carefully.
12. Maintain audit logs and recovery procedures.

### Key Takeaways

- Pull Requests can automatically trigger Terraform CI validation.
- `terraform fmt` and `terraform validate` do not require Azure
  authentication when backend initialization is disabled.
- Terraform Plan with our Azure remote backend requires access
  to Azure and the Terraform state.
- GitHub OIDC removes the need for stored Azure Client Secrets.
- App Registration and Service Principal Object IDs are different.
- GitHub permissions and Azure RBAC control different capabilities.
- A separate read-only PR identity reduces deployment privileges.
- Storage Blob Data Reader can still access sensitive state data.
- `-lock=false` and `-refresh=false` introduce important limitations.
- Fork restrictions alone do not make a PR workflow fully trusted.
- Our PR workflow successfully completed and was merged into `main`.

---

## Future Labs

The following topics are planned but are not yet implemented
in the current deployment workflow:

- Publishing sanitized Terraform Plan summaries in Pull Requests
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

---

# Lesson 8 – GitHub Actions Secrets, Variables & CI/CD Security

## 1. Objective

The goal of this lesson is to improve the configuration and security of our Terraform CI/CD pipelines by removing hardcoded Azure identifiers and using GitHub Actions Variables.

In this lesson, we:

- Configured Repository Variables and Environment Variables.
- Used separate Azure Service Principals for PR validation and deployment.
- Replaced hardcoded identifiers in both GitHub Actions workflows.
- Continued using Azure OIDC without client secrets.
- Preserved manual approval before Terraform Apply.
- Successfully tested Terraform Plan and Apply.

## 2. Repository Variables vs Environment Variables

### Repository Variables

Location:

`Settings → Secrets and variables → Actions → Variables`

Configured variables:

| Variable | Purpose |
|---|---|
| AZURE_PR_CLIENT_ID | Client ID of the read-only PR Service Principal |
| AZURE_DEPLOY_CLIENT_ID | Client ID of the deployment Service Principal |
| AZURE_TENANT_ID | Microsoft Entra tenant identifier |
| AZURE_SUBSCRIPTION_ID | Azure subscription identifier |

Repository Variables are available to eligible jobs throughout the repository.

Example from `terraform-pr.yml`:

```yaml
env:
  ARM_USE_OIDC: "true"
  ARM_USE_AZUREAD: "true"
  ARM_CLIENT_ID: ${{ vars.AZURE_PR_CLIENT_ID }}
  ARM_TENANT_ID: ${{ vars.AZURE_TENANT_ID }}
  ARM_SUBSCRIPTION_ID: ${{ vars.AZURE_SUBSCRIPTION_ID }}
```

### Environment Variables

Location:

`Settings → Environments → dev → Environment variables`

Configured variables:

| Variable | Purpose |
|---|---|
| AZURE_DEPLOY_CLIENT_ID | Deployment Client ID for DEV |
| AZURE_TENANT_ID | Tenant ID for DEV |
| AZURE_SUBSCRIPTION_ID | Subscription ID for DEV |

Environment Variables are available to jobs associated with that environment.

Example:

```yaml
jobs:
  terraform-apply:
    runs-on: ubuntu-latest
    environment:
      name: dev
```

### Variable precedence

If a Repository Variable and an Environment Variable share the same name, the Environment Variable takes precedence for a job associated with that environment.

Our deployment workflow uses the same expression in both jobs:

```yaml
ARM_CLIENT_ID: ${{ vars.AZURE_DEPLOY_CLIENT_ID }}
```

- `terraform-plan` reads the Repository Variable.
- `terraform-apply` reads the Environment Variable from `dev`.

Important: Apply jobs can also read Repository Variables. We use Environment Variables for deployment-specific configuration, not because Repository Variables are inaccessible.

## 3. Why We Use Two Azure Service Principals

We created two Azure identities following the principle of least privilege.

### PR Service Principal

App Registration:

`github-actions-terraform-pr-oidc`

Client ID:

`d3ebe1d4-46cd-49b4-961c-877c9533561b`

Azure permissions:

- Reader on `rg-github-oidc-lab`.
- Storage Blob Data Reader on the Terraform state container.

Used by:

`.github/workflows/terraform-pr.yml`

Purpose:

Validate proposed Terraform changes without infrastructure modification permissions.

### Deployment Service Principal

App Registration:

`github-actions-terraform-oidc`

Client ID:

`e0a670f6-2928-49a3-8532-aff461e897b8`

Azure permissions:

- Contributor on `rg-github-oidc-lab`.
- Storage Blob Data Contributor for Terraform state.

Used by:

`.github/workflows/terraform-deploy.yml`

Purpose:

Run Terraform Plan and execute approved Terraform Apply operations.

### Why not use one Service Principal?

The PR workflow only needs read access.

Giving it the same Contributor permissions as the deployment workflow would unnecessarily increase its privileges.

Separate identities reduce the impact of compromised credentials or workflows.

### Client ID vs Object ID

- Application (Client) ID identifies the application during authentication.
- Service Principal Object ID identifies its Enterprise Application object.
- Azure RBAC determines what the identity is allowed to do.

The Terraform variable `ARM_CLIENT_ID` expects the Application (Client) ID.

## 4. Azure OIDC Authentication

GitHub Actions authenticates to Azure using OpenID Connect (OIDC).

Authentication flow:

1. GitHub starts a workflow job.
2. GitHub issues an OIDC token for the job.
3. Microsoft Entra ID validates the token against configured federated credentials.
4. Azure issues an access token to the Service Principal.
5. Terraform accesses Azure using that identity and its RBAC permissions.

Required GitHub permissions:

```yaml
permissions:
  contents: read
  id-token: write
```

Azure Login:

```yaml
- name: Azure Login via OIDC
  uses: azure/login@v2
  with:
    client-id: ${{ env.ARM_CLIENT_ID }}
    tenant-id: ${{ env.ARM_TENANT_ID }}
    subscription-id: ${{ env.ARM_SUBSCRIPTION_ID }}
```

Terraform environment variables:

```yaml
ARM_USE_OIDC: "true"
ARM_USE_AZUREAD: "true"
ARM_CLIENT_ID: ${{ vars.AZURE_DEPLOY_CLIENT_ID }}
ARM_TENANT_ID: ${{ vars.AZURE_TENANT_ID }}
ARM_SUBSCRIPTION_ID: ${{ vars.AZURE_SUBSCRIPTION_ID }}
```

OIDC avoids storing long-lived Azure client secrets in GitHub.

Client ID, Tenant ID and Subscription ID are identifiers, not passwords.

## 5. Updating the PR Workflow

File:

`.github/workflows/terraform-pr.yml`

We replaced hardcoded Azure identifiers with Repository Variables.

The workflow now uses:

```yaml
ARM_CLIENT_ID: ${{ vars.AZURE_PR_CLIENT_ID }}
ARM_TENANT_ID: ${{ vars.AZURE_TENANT_ID }}
ARM_SUBSCRIPTION_ID: ${{ vars.AZURE_SUBSCRIPTION_ID }}
```

The PR pipeline performs:

1. Checkout repository.
2. Setup Terraform.
3. Terraform Format Check.
4. Azure Login via OIDC.
5. Terraform Init.
6. Terraform Validate.
7. Terraform Plan.

The PR pipeline does not declare `environment: dev`, so it uses Repository Variables.

We tested the updated workflow through a Pull Request and confirmed that the validation pipeline passed.

## 6. Updating the Deployment Workflow

File:

`.github/workflows/terraform-deploy.yml`

We removed hardcoded Azure identifiers from both deployment jobs.

Both jobs now contain:

```yaml
env:
  ARM_USE_OIDC: "true"
  ARM_USE_AZUREAD: "true"
  ARM_CLIENT_ID: ${{ vars.AZURE_DEPLOY_CLIENT_ID }}
  ARM_TENANT_ID: ${{ vars.AZURE_TENANT_ID }}
  ARM_SUBSCRIPTION_ID: ${{ vars.AZURE_SUBSCRIPTION_ID }}
```

### Terraform Plan job

The Plan job does not declare `environment: dev`.

Therefore, it reads Repository Variables.

Its main commands are:

```bash
terraform init -input=false
terraform fmt -check
terraform validate
terraform plan -input=false -no-color -out=tfplan
```

When the workflow operation is `apply`, the generated plan is uploaded as a GitHub Actions artifact.

### Terraform Apply job

The Apply job declares:

```yaml
terraform-apply:
  name: Terraform Apply
  if: inputs.operation == 'apply'
  needs: terraform-plan
  runs-on: ubuntu-latest

  environment:
    name: dev
```

This associates the job with the GitHub Environment `dev`.

The job can read the Environment Variables and is subject to its protection rules.

After approval, the saved plan is downloaded and executed:

```bash
terraform apply -input=false -no-color tfplan
```

This executes the previously generated Terraform plan.

## 7. Terraform Plan vs Terraform Apply

The workflow uses `workflow_dispatch` with an operation input:

```yaml
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
```

### Operation: plan

Execution flow:

```text
Workflow Dispatch
       |
       v
Terraform Plan
       |
       v
Workflow Complete
```

No Apply job runs.

No manual approval is required.

### Operation: apply

Execution flow:

```text
Workflow Dispatch
       |
       v
Terraform Plan
       |
       v
Upload tfplan Artifact
       |
       v
GitHub Environment: dev
       |
       v
Manual Approval
       |
       v
Terraform Apply
       |
       v
Workflow Complete
```

The Apply job uses:

```yaml
if: inputs.operation == 'apply'
needs: terraform-plan
```

This ensures Apply only runs after a successful Plan and only when the user selects the apply operation.

## 8. GitHub Environment Protection

Our `dev` Environment is configured with:

- Required reviewer approval.
- Deployment branch restriction to `main`.
- Environment-specific variables.

The Apply job waits for manual approval before starting.

In our lab, self-approval is permitted.

In production, independent reviewers and stricter separation of duties are recommended.

GitHub Environment rules control whether a deployment job may start.

Azure RBAC controls which Azure operations the Service Principal may perform.

These are separate security layers.

## 9. Testing and Verification

We successfully tested the updated deployment workflow.

### Terraform Plan

The Plan job passed using Repository Variables.

Azure OIDC login, Terraform initialization, validation and planning completed successfully.

### Manual Approval

The Apply job waited for approval through the GitHub Environment `dev`.

We reviewed and approved the deployment.

### Terraform Apply

After approval, the Apply job completed successfully.

Terraform output:

```text
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

Explanation:

- 0 added: No new resources were created.
- 0 changed: No existing resources were modified.
- 0 destroyed: No resources were deleted.

The saved Terraform plan contained no infrastructure changes.

### Git commit

Deployment workflow update:

```text
5308384 – Use GitHub variables for Terraform deployment authentication
```

## 10. Security Best Practices

### Principle of Least Privilege

Use separate identities for validation and deployment.

Assign only the Azure RBAC permissions required by each workflow.

### OIDC Instead of Client Secrets

Prefer federated identity credentials instead of long-lived client secrets.

Restrict OIDC trust to the intended repository, branch, environment or event.

### Protect Deployment Environments

Use required reviewers and branch restrictions.

Production environments should use independent approval.

### Protect Terraform State

Terraform state may contain sensitive values.

Use secure remote storage, encryption, access restrictions and state locking.

### Protect Terraform Plan Artifacts

Saved Terraform plans can contain sensitive data.

Limit artifact access and use short retention periods.

Our deployment workflow uses a one-day artifact retention period.

### Pull Request Workflow Security

Pull Request workflows with cloud authentication require special care.

Our lab limits credential-enabled PR validation to Pull Requests originating from the same repository.

This alone is not sufficient protection for untrusted contributions, because a branch may also modify workflow files.

Production pipelines should apply stronger controls to workflow changes and cloud authentication.

### Terraform PR Plan Limitations

Our PR workflow currently uses:

```bash
terraform plan -input=false -no-color -lock=false -refresh=false
```

Limitations:

- `-lock=false` disables state locking.
- `-refresh=false` skips refreshing Azure resource state.
- Infrastructure drift may not be detected.

These settings were chosen for our read-only validation lab and should not be considered a general production recommendation.

### Pin Third-Party Actions

For stronger supply-chain security, production workflows should pin external GitHub Actions to reviewed commit SHAs.

## 11. Key Takeaways

1. Repository Variables provide shared configuration across repository workflows.
2. Environment Variables provide environment-specific configuration.
3. Environment Variables override same-named Repository Variables for jobs associated with that environment.
4. Jobs using Environments can still read Repository Variables.
5. Terraform uses standard `ARM_*` variables for Azure authentication.
6. Separate Service Principals provide different Azure permissions for PR validation and deployment.
7. OIDC enables Azure authentication without stored client secrets.
8. GitHub Environment approvals protect deployment execution.
9. Terraform Apply can execute a previously saved Terraform plan.
10. Secure CI/CD combines GitHub permissions, OIDC, Azure RBAC and protected environments.

**Lesson 8 completed successfully.**


---

# Lesson 9 – Terraform CI/CD Security & Production Hardening

## 1. Objectives

In this lesson, we hardened our Terraform GitHub Actions CI/CD pipeline using:

- Least-privilege GitHub Actions permissions.
- Commit SHA pinning for third-party Actions.
- Azure Blob Storage security for Terraform remote state.
- Azure RBAC and OIDC authentication.
- GitHub Actions concurrency control.
- GitHub Environment approval protection.
- End-to-end Terraform Plan and Apply validation.

The lab uses:

- Repository: `Tomislav89/azure-learning-labs`
- Terraform directory: `github-actions/terraform-deployment-lab`
- Azure region: North Europe
- Resource group for state: `rg-terraform-state`
- Storage Account: `sttfstatezivkovic26`
- Blob container: `tfstate`
- State key: `github-actions-deployment.tfstate`

## 2. GitHub Actions Workflow Permissions

We use minimal GitHub Actions permissions.

At the workflow level:

```yaml
permissions:
  contents: read
```

For jobs requiring Azure OIDC authentication:

```yaml
permissions:
  contents: read
  id-token: write
```

Explanation:

- `contents: read` allows reading repository content.
- `id-token: write` allows requesting a GitHub OIDC token.
- The OIDC token is exchanged for Azure authentication.
- `id-token: write` does not automatically grant Azure permissions.
- Azure RBAC determines which Azure resources the identity can access.

The PR and deployment workflows use separate Azure identities.

## 3. GitHub Actions SHA Pinning

Originally, the workflows referenced Actions using major version tags:

```yaml
uses: actions/checkout@v4
uses: hashicorp/setup-terraform@v3
uses: azure/login@v2
```

Version tags can move to different commits.

For stronger supply-chain security, we replaced version tags with full commit SHAs.

Pinned Actions:

| Action | Commit SHA |
|---|---|
| actions/checkout | `11d5960a326750d5838078e36cf38b85af677262` |
| hashicorp/setup-terraform | `b9cd54a3c349d3f38e8881555d616ced269862dd` |
| azure/login | `7184910d9eb2b1c5e48f7073824a90609bb9b6d6` |
| actions/upload-artifact | `ea165f8d65b6e75b540449e92b4886f43607fa02` |
| actions/download-artifact | `d3f86a106a0bac45b974a628896c90dbdf5c8093` |

We replaced 11 Action references across two workflows.

Example:

```yaml
- name: Checkout repository
  uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262
```

Commands used to inspect Action references:

```bash
grep -n 'uses:' .github/workflows/terraform-pr.yml
grep -n 'uses:' .github/workflows/terraform-deploy.yml
```

To inspect a tag in an official Action repository:

```bash
git ls-remote https://github.com/actions/checkout.git \
  refs/tags/v4 refs/tags/v4^{}
```

For annotated Git tags, use the peeled commit SHA rather than the annotated tag object's SHA.

Security considerations:

- SHA pinning protects against a tag being moved.
- It does not prove that the pinned Action is free of vulnerabilities.
- Pinned versions must still be reviewed and updated.
- Dependabot or a similar process can help maintain pinned Actions.

Validation:

- Terraform Plan succeeded.
- Terraform Apply succeeded.
- Upload and download artifact steps were exercised.
- No infrastructure changes were required.

Commit:

```text
1031fba security: pin GitHub Actions to commit SHAs
```

## 4. Terraform Remote State Security

Terraform uses the AzureRM backend:

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

The state is stored in Azure Blob Storage rather than in the Git repository.

Important:

- State files may contain sensitive infrastructure information.
- Never commit `.tfstate` files to Git.
- Protect the backend using Azure RBAC.
- Protect against accidental deletion and overwriting.
- Use state locking during operations that modify state.

### 4.1 Inspect Storage Account Security

```bash
az storage account show \
  --name sttfstatezivkovic26 \
  --resource-group rg-terraform-state \
  --query '{
    httpsOnly:enableHttpsTrafficOnly,
    minTls:minimumTlsVersion,
    allowBlobPublicAccess:allowBlobPublicAccess,
    sharedKeyAccess:allowSharedKeyAccess
  }' \
  -o json
```

Verified:

- HTTPS-only access enabled.
- Minimum TLS version: TLS 1.2.
- Anonymous Blob access disabled.

### 4.2 Enable Blob Soft Delete

Blob Soft Delete allows recovery of deleted blobs during a retention period.

Command:

```bash
az storage account blob-service-properties update \
  --account-name sttfstatezivkovic26 \
  --resource-group rg-terraform-state \
  --enable-delete-retention true \
  --delete-retention-days 7
```

Verification:

```bash
az storage account blob-service-properties show \
  --account-name sttfstatezivkovic26 \
  --resource-group rg-terraform-state \
  --query "deleteRetentionPolicy" \
  -o json
```

Verified result:

```json
{
  "allowPermanentDelete": false,
  "days": 7,
  "enabled": true
}
```

### 4.3 Enable Blob Versioning

Blob Versioning preserves previous versions when a blob is modified.

Command:

```bash
az storage account blob-service-properties update \
  --account-name sttfstatezivkovic26 \
  --resource-group rg-terraform-state \
  --enable-versioning true \
  --output none
```

Verification:

```bash
az storage account blob-service-properties show \
  --account-name sttfstatezivkovic26 \
  --resource-group rg-terraform-state \
  --query "isVersioningEnabled" \
  -o json
```

Verified result:

```text
true
```

Important:

- Versioning does not replace backups.
- Previous versions consume storage.
- Restoring an older Terraform state requires careful analysis because it may not match actual Azure resources.

### 4.4 Configure Lifecycle Management

We created a lifecycle rule to delete previous versions older than 30 days.

The rule targets only:

```text
tfstate/github-actions-deployment.tfstate
```

Lifecycle JSON:

```json
{
  "rules": [
    {
      "enabled": true,
      "name": "cleanup-old-terraform-state-versions",
      "type": "Lifecycle",
      "definition": {
        "filters": {
          "blobTypes": ["blockBlob"],
          "prefixMatch": [
            "tfstate/github-actions-deployment.tfstate"
          ]
        },
        "actions": {
          "version": {
            "delete": {
              "daysAfterCreationGreaterThan": 30
            }
          }
        }
      }
    }
  ]
}
```

Command to apply a saved JSON policy:

```bash
az storage account management-policy create \
  --account-name sttfstatezivkovic26 \
  --resource-group rg-terraform-state \
  --policy @/tmp/terraform-state-lifecycle.json
```

The JSON must first be saved to the specified file.

Verification:

```bash
az storage account management-policy show \
  --account-name sttfstatezivkovic26 \
  --resource-group rg-terraform-state \
  --query "policy.rules" \
  -o json
```

Important:

- The lifecycle rule targets previous versions, not the current state.
- Lifecycle processing is asynchronous.
- Other Terraform state blobs in the same container are not covered by this rule.

## 5. Azure RBAC and Least Privilege

Two GitHub Actions Service Principals are used.

### PR Service Principal

Name:

```text
github-actions-terraform-pr-oidc
```

Container role:

```text
Storage Blob Data Reader
```

Purpose:

- Read Terraform remote state.
- Run PR validation.
- Avoid granting write access to Terraform state.

### Deploy Service Principal

Name:

```text
github-actions-terraform-oidc
```

Container role:

```text
Storage Blob Data Contributor
```

Purpose:

- Read and update Terraform state.
- Acquire and release state locks.
- Execute Terraform deployment operations.

The deployment identity also has the required Azure resource-management permissions on the deployment resource group.

Commands used to inspect RBAC:

```bash
STORAGE_ID=$(az storage account show \
  --name sttfstatezivkovic26 \
  --resource-group rg-terraform-state \
  --query id -o tsv)

az role assignment list \
  --scope "$STORAGE_ID" \
  --include-inherited \
  -o table

az role assignment list \
  --scope "$STORAGE_ID/blobServices/default/containers/tfstate" \
  -o table
```

Do not combine `--all` and `--scope` in these Azure CLI commands.

Verify Service Principal identity:

```bash
az ad sp show \
  --id cfb7f91c-b5b8-4c6d-8284-8f86d1a1654b \
  --query "{name:displayName,appId:appId,objectId:id}" \
  -o json

az ad sp show \
  --id 739cdef8-a47a-4650-be24-913c906c6799 \
  --query "{name:displayName,appId:appId,objectId:id}" \
  -o json
```

## 6. Disable Shared Key Access

Our Terraform workflows use:

```yaml
ARM_USE_OIDC: "true"
ARM_USE_AZUREAD: "true"
```

The backend uses:

```hcl
use_azuread_auth = true
use_oidc         = true
```

We disabled Shared Key authentication:

```bash
az storage account update \
  --name sttfstatezivkovic26 \
  --resource-group rg-terraform-state \
  --allow-shared-key-access false \
  --output none
```

Verification:

```bash
az storage account show \
  --name sttfstatezivkovic26 \
  --resource-group rg-terraform-state \
  --query "{sharedKeyAccess:allowSharedKeyAccess,httpsOnly:enableHttpsTrafficOnly}" \
  -o json
```

Verified:

```json
{
  "httpsOnly": true,
  "sharedKeyAccess": false
}
```

Why:

- Shared Key authentication can bypass data-plane RBAC restrictions.
- Entra ID authentication uses identity-based access controls.
- GitHub Actions uses OIDC rather than stored client secrets.

Warning:

Disabling Shared Key authentication may break other applications or scripts that depend on Storage Account keys.

Rollback if required:

```bash
az storage account update \
  --name sttfstatezivkovic26 \
  --resource-group rg-terraform-state \
  --allow-shared-key-access true \
  --output none
```

## 7. Validate Terraform Backend

Local validation:

```bash
cd ~/workspace/azure-learning-labs/github-actions/terraform-deployment-lab

terraform init -input=false -no-color
terraform state list
```

Verified state entries:

```text
data.azurerm_resource_group.lab
azurerm_storage_account.lab
```

The local backend remained functional after Shared Key authentication was disabled.

We also ran the GitHub Actions Terraform deployment workflow.

Verified:

```text
Acquiring state lock.
Releasing state lock.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

This confirmed that GitHub OIDC authentication and Terraform state access continued working after the security change.

## 8. GitHub Actions Concurrency Control

Concurrency controls how overlapping GitHub Actions workflow runs are handled.

### 8.1 Deployment Workflow

Configured in:

```text
.github/workflows/terraform-deploy.yml
```

Configuration:

```yaml
concurrency:
  group: terraform-deployment-lab
  cancel-in-progress: false
```

Explanation:

- Runs in the same concurrency group cannot execute simultaneously.
- A new run does not cancel the currently executing deployment.
- GitHub normally permits one running and one pending run per group.
- A newer pending run may replace an older pending run.
- Concurrency is not a guaranteed FIFO queue.

### 8.2 PR Workflow

Configured in:

```text
.github/workflows/terraform-pr.yml
```

Configuration:

```yaml
concurrency:
  group: terraform-pr-${{ github.event.pull_request.number }}
  cancel-in-progress: true
```

Explanation:

- Each Pull Request has its own concurrency group.
- A new run of the same PR cancels its previous run.
- Different PRs can run independently.
- This reduces unnecessary execution of outdated validation runs.

Git workflow used:

```bash
git switch -c feature/terraform-pr-concurrency

git add .github/workflows/terraform-pr.yml

git commit -m "ci: add concurrency control to Terraform PR workflow"

git push -u origin feature/terraform-pr-concurrency
```

The change was validated through a Pull Request and merged into `main`.

Relevant commits:

```text
4f8c0e9 ci: add concurrency control to Terraform PR workflow
e648155 Merge pull request #6 from Tomislav89/feature/terraform-pr-concurrency
```

Note:

The successful PR run validated the configuration, but overlapping PR runs were not separately simulated to demonstrate automatic cancellation.

## 9. GitHub Environment Approval

The Terraform Apply job uses:

```yaml
terraform-apply:
  if: inputs.operation == 'apply'
  needs: terraform-plan

  environment:
    name: dev
```

Explanation:

- Apply runs only when `operation` is `apply`.
- Apply depends on a successful Plan job.
- The GitHub Environment applies configured deployment protection rules.
- Required reviewers must approve the deployment before the protected job starts.

Verified `dev` Environment settings:

- Required reviewers enabled.
- Reviewer: `Tomislav89`.
- Self-review allowed for this lab.
- Wait timer disabled.
- Allowed deployment branch: `main`.
- Environment variables configured for Azure deployment authentication.
- No Azure client secret stored in Environment secrets.

The deployment uses a saved Terraform plan artifact.

Plan job:

```bash
terraform plan -input=false -no-color -out=tfplan
```

Apply job:

```bash
terraform apply -input=false -no-color tfplan
```

### Production Recommendations

For production deployments:

- Use a dedicated `prod` GitHub Environment.
- Require approval from a different authorized reviewer.
- Disable administrator bypass where appropriate.
- Restrict deployment branches.
- Use a separate production Azure identity.
- Use a separate production Terraform state.
- Apply least-privilege Azure RBAC.
- Review Terraform plans before approval.
- Protect plan artifacts because they may contain sensitive information.
- Review how plan artifacts are transferred between jobs.

Environment approval controls when a job can start.

Azure RBAC controls which Azure operations the authenticated identity can perform.

Both controls are needed.

## 10. Terraform State Locking

Terraform uses Azure Blob leases to coordinate state access.

Observed during Apply:

```text
Acquiring state lock. This may take a few moments...
Releasing state lock. This may take a few moments...
```

State locking helps prevent simultaneous state modifications.

GitHub Actions concurrency and Terraform state locking solve related but different problems:

- Concurrency coordinates GitHub workflow runs.
- State locking coordinates Terraform operations accessing the same state.

Our PR workflow uses:

```bash
terraform plan -input=false -no-color -lock=false -refresh=false
```

This was selected for the read-only validation lab.

Limitations:

- State locking is disabled for this PR plan.
- Azure resource refresh is disabled.
- Infrastructure drift may not be detected.
- Concurrent infrastructure changes can make the plan stale.

These flags are not general production recommendations.

## 11. Troubleshooting

### Terraform backend authentication fails

Check:

```bash
az account show -o table
```

Verify:

- Azure authentication is valid.
- The Service Principal has the correct Blob Data role.
- The backend is configured for Entra ID authentication.
- GitHub OIDC federation matches the workflow context.
- The Storage Account allows the intended network access.

### Shared Key authentication errors

After disabling Shared Key access, applications using Storage Account keys may fail.

Verify:

```bash
az storage account show \
  --name sttfstatezivkovic26 \
  --resource-group rg-terraform-state \
  --query "allowSharedKeyAccess" \
  -o json
```

Expected:

```text
false
```

### Terraform state is locked

A running Terraform operation may hold a Blob lease.

Do not immediately force-unlock.

First:

1. Check whether another Terraform operation is running.
2. Check GitHub Actions workflow status.
3. Wait for the active operation to finish.
4. Investigate stale locks before considering manual intervention.

### Azure CLI RBAC command fails

Do not combine:

```text
--all
--scope
```

Use a scoped query instead:

```bash
az role assignment list --scope "$STORAGE_ID" -o table
```

### Lifecycle policy not found

If Azure returns:

```text
ManagementPolicyNotFound
```

No lifecycle management policy currently exists on the Storage Account.

### GitHub Actions deployment is waiting

Check:

- Environment required reviewers.
- Deployment branch restrictions.
- Pending approval status.
- Workflow concurrency group.

## 12. Final Validation

Successfully completed:

1. Workflow permission review.
2. GitHub Actions SHA pinning.
3. Terraform state Soft Delete.
4. Terraform state Blob Versioning.
5. Lifecycle Management configuration.
6. Azure RBAC verification.
7. Shared Key authentication disabled.
8. Local Terraform backend validation.
9. GitHub OIDC Terraform Plan and Apply validation.
10. Deployment concurrency verification.
11. PR concurrency implementation and merge.
12. GitHub Environment approval verification.

Final Terraform Apply:

```text
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

No infrastructure changes were required during the final validation.

**Lesson 9 completed successfully.**


---

# GitHub Actions – Lesson 10: Reusable Workflows and Outputs

## 1. Objective

The objective of this lesson is to understand how to create reusable GitHub Actions workflows, pass input parameters, return output values, and organize Terraform CI pipelines without duplicating workflow logic.

The implementation uses two workflows:

- `.github/workflows/terraform-pr.yml` – caller workflow.
- `.github/workflows/terraform-reusable-plan.yml` – reusable workflow.

Both workflows were implemented, tested through Pull Requests, and merged into the main branch.

## 2. Why Reusable Workflows?

Without reusable workflows, multiple pipelines may contain identical steps:

- Checkout repository.
- Setup Terraform.
- Terraform Format Check.
- Azure Login via OIDC.
- Terraform Init.
- Terraform Validate.
- Terraform Plan.

Duplicating these steps increases maintenance effort and the risk of inconsistent configurations.

Reusable workflows allow common CI logic to be defined once and invoked by other workflows.

Benefits:

1. Reduced code duplication.
2. Centralized pipeline maintenance.
3. Consistent Terraform validation.
4. Easier parameterization.
5. Improved separation of responsibilities.

## 3. Caller vs Reusable Workflow

### Caller Workflow

File:

`.github/workflows/terraform-pr.yml`

The caller determines when the pipeline runs and which reusable workflow should execute.

Example:

```yaml
on:
  pull_request:
    branches:
      - main

jobs:
  terraform-pr-validation:
    uses: ./.github/workflows/terraform-reusable-plan.yml

    with:
      terraform_directory: github-actions/terraform-deployment-lab
```

The caller passes the Terraform directory using `with`.

### Reusable Workflow

File:

`.github/workflows/terraform-reusable-plan.yml`

The reusable workflow contains the actual Terraform validation steps.

It is invoked through:

```yaml
on:
  workflow_call:
```

The reusable workflow does not require its own independent Pull Request trigger.

## 4. workflow_call vs pull_request

`pull_request` is an event trigger.

Example:

```yaml
on:
  pull_request:
    branches:
      - main
```

It starts the workflow when a matching Pull Request event occurs.

`workflow_call` enables another workflow to invoke the reusable workflow.

Example:

```yaml
on:
  workflow_call:
```

The caller receives the event and invokes the reusable workflow.

## 5. Inputs and with

Reusable workflow:

```yaml
on:
  workflow_call:
    inputs:
      terraform_directory:
        description: "Directory containing Terraform configuration"
        required: true
        type: string
```

Explanation:

- `inputs` defines accepted input parameters.
- `terraform_directory` is the parameter name.
- `required: true` means the caller must supply it.
- `type: string` means the parameter is textual.

Caller:

```yaml
with:
  terraform_directory: github-actions/terraform-deployment-lab
```

The caller supplies the actual directory.

Inside the reusable workflow:

```yaml
- name: Terraform Init
  working-directory: ${{ inputs.terraform_directory }}
  run: terraform init -input=false
```

GitHub Actions resolves the input to:

`github-actions/terraform-deployment-lab`

The Terraform Init command runs from that directory.

This is conceptually equivalent to changing into the directory before executing Terraform Init.

## 6. Step Outputs

A step can produce a named output using the GitHub Actions environment file referenced by `$GITHUB_OUTPUT`.

Example:

```yaml
- name: Set Validation Result
  id: result
  run: echo "status=passed" >> "$GITHUB_OUTPUT"
```

Explanation:

- `id: result` identifies the step.
- `status` is the output name.
- `passed` is the output value.
- `$GITHUB_OUTPUT` is a predefined GitHub Actions environment variable containing a file path.
- `>>` appends the output declaration to that file.

The step output is accessed through:

```yaml
${{ steps.result.outputs.status }}
```

Reference breakdown:

- `steps` – built-in GitHub Actions context.
- `result` – value defined in `id: result`.
- `outputs` – built-in property containing step outputs.
- `status` – output name written to `$GITHUB_OUTPUT`.

The names `result` and `status` are user-defined.

The variable name `GITHUB_OUTPUT` is predefined by GitHub Actions and should not be renamed.

The output is set after the Terraform Plan step, so under normal step execution the result step runs only when the preceding Terraform checks have succeeded.

## 7. Job Outputs

A step output is initially accessible within its job.

To expose the value as a job output:

```yaml
jobs:
  terraform-plan:
    runs-on: ubuntu-latest

    outputs:
      validation_status: ${{ steps.result.outputs.status }}
```

Explanation:

- `outputs` declares outputs of the job.
- `validation_status` is the job output name.
- `steps.result.outputs.status` references the earlier step output.

The resulting job output is:

`validation_status = passed`

## 8. Reusable Workflow Outputs

To return the job output to the caller, the reusable workflow must declare an output under `workflow_call`.

```yaml
on:
  workflow_call:
    outputs:
      validation_status:
        description: "Terraform validation result"
        value: ${{ jobs.terraform-plan.outputs.validation_status }}
```

Explanation:

- `workflow_call.outputs` declares outputs exposed to callers.
- `validation_status` is the public workflow output name.
- `jobs.terraform-plan.outputs.validation_status` references the job output.

The complete data flow is:

```text
Step:
  echo "status=passed" >> "$GITHUB_OUTPUT"
                  |
                  v
Step Output:
  steps.result.outputs.status
                  |
                  v
Job Output:
  validation_status
                  |
                  v
Workflow Output:
  jobs.terraform-plan.outputs.validation_status
                  |
                  v
Caller:
  needs.terraform-pr-validation.outputs.validation_status
```

## 9. Reading Outputs in the Caller

The caller contains a job that invokes the reusable workflow:

```yaml
jobs:
  terraform-pr-validation:
    uses: ./.github/workflows/terraform-reusable-plan.yml

    with:
      terraform_directory: github-actions/terraform-deployment-lab
```

A second job reads the result:

```yaml
  show-validation-result:
    name: Show Validation Result
    needs: terraform-pr-validation
    runs-on: ubuntu-latest

    steps:
      - name: Display Terraform Validation Result
        env:
          VALIDATION_STATUS: ${{ needs.terraform-pr-validation.outputs.validation_status }}
        run: echo "Terraform validation status is $VALIDATION_STATUS"
```

Explanation:

- `needs: terraform-pr-validation` establishes a dependency.
- The second job waits for the reusable workflow job to finish successfully.
- `needs.terraform-pr-validation.outputs.validation_status` reads the returned output.
- `env` passes the value to the shell step.
- `$VALIDATION_STATUS` accesses the shell environment variable.

Expected output:

```text
Terraform validation status is passed
```

## 10. Security Architecture

The reusable Terraform PR workflow uses GitHub OIDC authentication.

Relevant settings:

```yaml
permissions:
  contents: read
  id-token: write
```

`contents: read` allows repository checkout.

`id-token: write` allows the job to request an OIDC token for Azure authentication.

Azure configuration:

```yaml
env:
  ARM_USE_OIDC: "true"
  ARM_USE_AZUREAD: "true"
  ARM_CLIENT_ID: ${{ vars.AZURE_PR_CLIENT_ID }}
  ARM_TENANT_ID: ${{ vars.AZURE_TENANT_ID }}
  ARM_SUBSCRIPTION_ID: ${{ vars.AZURE_SUBSCRIPTION_ID }}
```

The PR workflow uses a separate Azure identity from the deployment workflow.

The PR identity has read-only access to the Terraform state container.

The PR Terraform Plan command uses:

```bash
terraform plan -input=false -no-color -lock=false -refresh=false
```

The PR workflow is restricted to same-repository Pull Requests:

```yaml
if: github.event_name == 'pull_request' && github.event.pull_request.head.repo.full_name == github.repository
```

This prevents the privileged Terraform validation job from running for fork-based Pull Requests.

The deployment workflow remains separate and retains its own Azure identity, state-locking behavior, saved plan artifact, and environment approval process.

## 11. Practical Implementation and Testing

### Pull Request #7 – Reusable Workflow

Feature branch:

`feature/terraform-reusable-workflow`

Commit:

`dfc070c ci: introduce reusable Terraform PR workflow`

Implemented:

- Reusable Terraform PR workflow.
- `workflow_call` trigger.
- Required `terraform_directory` input.
- Caller using job-level `uses`.
- Terraform validation steps moved to the reusable workflow.
- Existing OIDC and security restrictions preserved.

GitHub Actions validation passed.

Merge commit:

`fd3a3f9`

### Pull Request #8 – Workflow Outputs

Feature branch:

`feature/terraform-reusable-outputs`

Commit:

`410ccf8 ci: expose reusable Terraform validation outputs`

Implemented:

- Step output using `$GITHUB_OUTPUT`.
- Job output `validation_status`.
- Reusable workflow output `validation_status`.
- Caller job `show-validation-result`.
- Dependency using `needs`.
- Output access using the `needs` context.

GitHub Actions results:

- Reusable Terraform Plan – successful in 36 seconds.
- Show Validation Result – successful in 3 seconds.

Both checks passed.

Merge commit:

`5a60b99`

The checks confirmed successful execution of both jobs. The exact displayed output text was not separately recorded in the terminal evidence.

## 12. Validation Commands

Validate workflow YAML syntax:

```bash
python3 - <<'PY'
from pathlib import Path
import yaml

for name in [
    ".github/workflows/terraform-reusable-plan.yml",
    ".github/workflows/terraform-pr.yml",
]:
    with Path(name).open() as f:
        yaml.safe_load(f)
    print(f"YAML syntax OK: {name}")
PY
```

Check Git changes:

```bash
git diff --check
git diff --stat
git status --short
```

Verify commits:

```bash
git log -3 --oneline
```

Note: YAML parsing validates basic syntax but does not replace GitHub Actions workflow execution or semantic validation.

## 13. Key Takeaways

1. `pull_request` starts the caller workflow.
2. `workflow_call` allows a workflow to be invoked by another workflow.
3. `uses` identifies the reusable workflow.
4. `with` passes input values.
5. `inputs` receives those values.
6. `working-directory` determines where commands execute.
7. `$GITHUB_OUTPUT` creates step outputs.
8. `steps.<step_id>.outputs.<name>` reads step outputs.
9. Job outputs expose step values at job level.
10. Workflow outputs expose job values to callers.
11. `needs` establishes job dependencies and allows access to their outputs.
12. Reusable PR validation and deployment workflows must retain appropriate security boundaries.

**Lesson 10 – Reusable Workflows and Outputs: implementation completed and tested.**
