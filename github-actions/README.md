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

## Future Labs

The following topics are planned but are not yet implemented
in the current Terraform CI workflow:

- GitHub Actions permissions and environment protection
- Terraform plan automation
- Controlled Terraform apply
- Secure handling of credentials and configuration
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
