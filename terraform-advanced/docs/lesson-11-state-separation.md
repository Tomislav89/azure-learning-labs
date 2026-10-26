# Lesson 11 – Terraform State Separation and Migration

## 1. Objective

The goal of this lesson was to migrate an existing Terraform deployment
from one shared state into two independent Terraform states.

Original architecture:

    environments/dev/
        |
        v
    dev.tfstate
        |
        +-- Resource Group
        +-- Network Security Group
        +-- Virtual Network
        +-- Four Subnets
        +-- Network Interface

The original state contained 8 managed resource instances.

Target architecture:

    environments/dev-separated/
        |
        +-- networking/
        |      |
        |      +-- dev-networking.tfstate
        |             |
        |             +-- Resource Group
        |             +-- Network Security Group
        |             +-- Virtual Network
        |             +-- Four Subnets
        |
        +-- compute/
               |
               +-- dev-compute.tfstate
                      |
                      +-- Network Interface

The networking state contains 7 resource instances.

The compute state contains 1 resource instance.

The migration was performed without intentionally recreating
the existing Azure infrastructure.

After migration, both configurations produced clean Terraform plans.

The Azure resources were later destroyed deliberately to avoid costs.

## 2. Why Separate Terraform State?

Terraform state maps resource addresses in configuration
to infrastructure objects managed by Terraform.

When many unrelated resources share one state, every operation
uses the same state and dependency graph.

Separating state can provide:

- Smaller plans
- Independent deployments
- Reduced blast radius
- Clear ownership boundaries
- Independent infrastructure lifecycles
- Better organization of large projects

For example, a networking team may manage virtual networks
while an application team manages compute resources.

However, state separation introduces dependencies between
independent configurations.

Those dependencies must be handled explicitly.

IMPORTANT:

Separate state files do not automatically provide security isolation.
Backend access permissions must also be configured appropriately.

## 3. Initial Terraform State

The original DEV environment used:

    dev.tfstate

The state contained these resource addresses:

    azurerm_network_security_group.app
    azurerm_resource_group.this
    module.compute.azurerm_network_interface.this
    module.networking.azurerm_subnet.this["app"]
    module.networking.azurerm_subnet.this["db"]
    module.networking.azurerm_subnet.this["management"]
    module.networking.azurerm_subnet.this["web"]
    module.networking.azurerm_virtual_network.this

The goal was to move the network interface into a separate
compute state while keeping the other seven resources
in the networking state.

## 4. State Backup Before Migration

Before changing state, we created a local backup.

Command:

    terraform state pull > dev-state-backup.json

Explanation:

terraform state pull:
Downloads the current state snapshot from the configured backend.

> dev-state-backup.json:
Redirects the downloaded JSON into a local backup file.

This does not change Azure infrastructure.

The backup protects against accidental loss or corruption
during state manipulation.

We then created a working copy:

    cp dev-state-backup.json dev-state-working.tfstate

Explanation:

cp:
Copies a file.

dev-state-backup.json:
Original backup that should remain unchanged.

dev-state-working.tfstate:
Working copy used for state manipulation.

IMPORTANT:

State backups may contain credentials, secrets and sensitive
infrastructure metadata.

They must never be committed to GitHub.

## 5. Validating the Backup

We checked whether the backup contained valid JSON.

Command:

    python3 -m json.tool dev-state-backup.json > /dev/null

Explanation:

python3 -m json.tool:
Parses JSON and reports syntax errors.

> /dev/null:
Discards normal output.

A successful exit status indicates valid JSON syntax.

This does not guarantee that the state is semantically valid
or compatible with a destination backend.

We also inspected the number of managed resource instances.

Example Python script:

    import json

    with open("dev-state-backup.json") as f:
        state = json.load(f)

    count = 0

    for resource in state["resources"]:
        count += len(resource.get("instances", []))

    print("Number of resource instances:", count)

Explanation:

json.load(f):
Converts the JSON document into Python dictionaries and lists.

state["resources"]:
Contains resource records tracked by Terraform.

resource.get("instances", []):
Returns the instances belonging to a resource record.

len(...):
Counts those instances.

The original state contained 8 managed resource instances.

A Terraform resource record and a resource instance
are not always the same thing.

For example, resources created with for_each may have
multiple instances under one resource record.

## 6. Moving a Resource Between Local State Files

We used terraform state mv to move the network interface
out of the working state.

Command:

    terraform state mv \
      -state=dev-state-working.tfstate \
      -state-out=dev-compute-local.tfstate \
      'module.compute.azurerm_network_interface.this' \
      'module.compute.azurerm_network_interface.this'

Explanation:

terraform state mv:
Moves a Terraform resource address between state locations.

-state:
Specifies the source local state file.

-state-out:
Specifies the destination local state file.

First resource address:
The address in the source state.

Second resource address:
The address in the destination state.

Both addresses are identical because the resource's
Terraform address did not change.

Only its state ownership changed.

After this operation:

    dev-state-working.tfstate
        7 managed resource instances

    dev-compute-local.tfstate
        1 managed resource instance

IMPORTANT:

Moving state does not create, update or delete Azure resources.

It changes Terraform's record of which state manages them.

This was a local-file operation using explicitly selected
state files, not a direct migration between two Azure backends.

## 7. Root Outputs and State Separation

The original DEV root configuration exposed outputs including:

    app_subnet_id
    nic_id

After separating the state, networking should expose
the application subnet ID.

Compute should manage and expose the network interface ID.

We needed to avoid leaving an obsolete compute output
in the networking state.

A simplified version of the Python operation used:

    import json

    path = "dev-state-working.tfstate"

    with open(path) as f:
        state = json.load(f)

    state["outputs"].pop("nic_id", None)
    state["serial"] += 1

    with open(path, "w") as f:
        json.dump(state, f, indent=2)

Explanation:

state["outputs"]:
Dictionary containing root output values stored in state.

.pop("nic_id", None):
Removes the nic_id output if it exists.

The None argument prevents an error if the key is missing.

state["serial"] += 1:
Increments the state serial number after manual modification.

json.dump(...):
Writes the modified JSON back to disk.

IMPORTANT:

This was a controlled lab-specific operation.

Direct editing of Terraform state JSON is risky and
should not be the default production migration method.

Whenever possible, prefer Terraform-supported state commands,
configuration refactoring and carefully planned migration procedures.

## 8. Understanding State Lineage

Terraform state contains a lineage identifier.

Conceptual example:

    "lineage": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

Lineage identifies the history of a Terraform state.

It helps Terraform detect attempts to overwrite
an unrelated state with another state snapshot.

Different independently initialized states normally
have different lineage identifiers.

During our migration, the destination backends were
initialized separately and had their own lineages.

We adjusted local migration copies to match the intended
destination state lineages before pushing them.

This was done because Terraform performs safety checks
when accepting a state snapshot.

IMPORTANT:

Never blindly copy lineage values between state files.

Changing lineage incorrectly can defeat an important
safety mechanism and lead to state corruption or data loss.

## 9. Understanding State Serial

Terraform state also contains a serial number.

Conceptual example:

    "serial": 15

Serial is a version counter for state snapshots.

When Terraform updates state, the serial normally increases.

Terraform uses serial information to help detect
whether a state snapshot is older than the destination.

In our lab, manual JSON changes required careful
handling of the serial number.

We incremented serial values in local migration copies
before pushing them to the appropriate backends.

IMPORTANT:

Increasing a serial number does not make a state safe.

Lineage, serial, resource addresses, outputs and the
actual infrastructure must all be consistent.

Do not use terraform state push -force merely to bypass
a safety error without understanding its cause.

## 10. Separate Azure Storage Backends

Both new configurations used Azure Storage.

Networking backend:

    terraform {
      backend "azurerm" {
        resource_group_name  = "rg-terraform-state"
        storage_account_name = "sttfstatezivkovic26"
        container_name       = "tfstate"
        key                  = "dev-networking.tfstate"
        use_azuread_auth     = true
      }
    }

Compute backend:

    terraform {
      backend "azurerm" {
        resource_group_name  = "rg-terraform-state"
        storage_account_name = "sttfstatezivkovic26"
        container_name       = "tfstate"
        key                  = "dev-compute.tfstate"
        use_azuread_auth     = true
      }
    }

The backend storage account and container are shared.

The state blobs are different.

This means networking and compute have independent
Terraform state snapshots.

Both backends were initialized before importing
the migrated state snapshots.

## 11. Pushing Migrated State to Azure Storage

The Terraform command used for writing a prepared
local state snapshot to the configured backend was:

    terraform state push PATH_TO_PREPARED_STATE_FILE

For example, from the networking root configuration,
the prepared networking snapshot was pushed to its backend.

From the compute root configuration, the prepared
compute snapshot was pushed to its backend.

Explanation:

terraform state push:
Replaces the current backend state with the supplied
local state snapshot, subject to Terraform safety checks.

The current working directory determines which
configured backend receives the state.

This is why checking the backend key before pushing
is extremely important.

Our migration copies were prepared with matching
destination lineages and appropriate serial values.

WARNING:

terraform state push is a potentially destructive
state operation.

Do not run it casually.

Before any production state push:

- Back up source and destination state.
- Verify the active backend.
- Verify lineage and serial.
- Confirm the resource address mapping.
- Coordinate with other Terraform users.
- Prevent concurrent Terraform operations.
- Prepare a tested recovery procedure.

The commands in this document describe a completed lab.
They are not intended as a blind copy-paste migration script.

## 12. Remote State Outputs

After migration, the networking root configuration
exposed the application subnet ID:

    output "app_subnet_id" {
      description = "ID of the DEV application subnet"
      value       = module.networking.app_subnet_id
    }

This output is stored in:

    dev-networking.tfstate

The compute configuration reads it using:

    data "terraform_remote_state" "networking" {
      backend = "azurerm"

      config = {
        resource_group_name  = "rg-terraform-state"
        storage_account_name = "sttfstatezivkovic26"
        container_name       = "tfstate"
        key                  = "dev-networking.tfstate"
        use_azuread_auth     = true
      }
    }

The compute module then uses:

    subnet_id = data.terraform_remote_state.networking.outputs.app_subnet_id

Explanation:

data.terraform_remote_state.networking:
Reads the networking Terraform state.

outputs:
Accesses root outputs stored in that state.

app_subnet_id:
The exported subnet ID.

The compute configuration does not directly read
the networking module's local outputs.tf file.

It reads the output value stored in the remote state.

This is an important distinction.

## 13. Backing Up the Original Azure Blob

Before retiring the original state, we created
an additional backup in Azure Storage.

The source blob was:

    dev.tfstate

The backup blob was:

    dev-pre-separation-backup.tfstate

We used an Azure CLI blob copy operation and
verified that the backup existed.

The relevant Azure CLI operation was:

    az storage blob copy start

This starts a blob copy operation.

A successful start response does not always mean
the asynchronous copy has completed.

The destination blob and copy status should be checked
before treating the backup as complete.

Keeping a separate remote backup protects against
mistakes made during retirement of the original state.

## 14. Retiring the Original DEV State

After networking and compute were successfully migrated,
the original dev.tfstate still existed.

We did not want the old state to continue claiming
ownership of the same Azure resources.

The original state was therefore retired.

We prepared an updated state snapshot with:

    "resources": []

    "outputs": {}

The state serial was incremented.

The retired snapshot was then pushed to the original backend.

Explanation:

resources = []:
Removes managed resource records from the state snapshot.

outputs = {}:
Removes root output values from the state snapshot.

IMPORTANT:

Removing resources from Terraform state does not delete
the actual Azure resources.

It only removes Terraform's tracking of those resources.

This operation is very different from terraform destroy.

terraform destroy requests deletion of managed infrastructure.

Removing resource records from state leaves the
infrastructure in Azure unless it is separately deleted.

The original state backup was preserved.

## 15. Verification After Migration

After migration, we checked both new root configurations.

Networking:

    cd environments/dev-separated/networking

    terraform plan

Compute:

    cd environments/dev-separated/compute

    terraform plan

Both configurations eventually produced:

    No changes. Your infrastructure matches the configuration.

This confirmed that, at the time of verification,
Terraform did not detect infrastructure changes
required by either new configuration.

We also checked the old state to ensure that it
no longer tracked the migrated resources.

## 16. Final Cleanup

After completing the migration lab, we removed
the deployed Azure resources to avoid ongoing costs.

The destruction order was:

    1. Compute
    2. Networking

Compute:

    cd environments/dev-separated/compute
    terraform destroy

This removed the network interface.

Networking:

    cd environments/dev-separated/networking
    terraform destroy

This removed the seven networking resources.

We also verified that the DEV resource group
no longer existed:

    az group exists --name rg-terraform-dev

Result:

    false

The Azure Storage backend was retained.

IMPORTANT:

Do not delete the remote state storage account
without checking which other Terraform environments
depend on it.

## 17. Production-Safe Migration Principles

This lab demonstrated how Terraform state ownership works.

In a production environment, a migration requires
additional controls.

Recommended principles:

1. Freeze infrastructure changes during migration.
2. Identify all resources and dependencies.
3. Back up all affected states.
4. Prefer supported Terraform state operations.
5. Avoid manual JSON editing where possible.
6. Verify backend destinations before every state operation.
7. Never allow two active states to manage the same resource.
8. Validate outputs consumed by other configurations.
9. Run plans against every affected configuration.
10. Document rollback and recovery procedures.
11. Use least-privilege access to remote state.
12. Keep state backups out of source control.

A state migration should be planned as an infrastructure
change with the same care as a production deployment.

## 18. Common Commands Reference

Read current backend state:

    terraform state pull

List tracked resources:

    terraform state list

Inspect one tracked resource:

    terraform state show RESOURCE_ADDRESS

Move resource state:

    terraform state mv SOURCE_ADDRESS DESTINATION_ADDRESS

Remove resource tracking without deleting infrastructure:

    terraform state rm RESOURCE_ADDRESS

Push a prepared state snapshot:

    terraform state push PATH_TO_STATE_FILE

Validate Terraform configuration:

    terraform validate

Preview infrastructure changes:

    terraform plan

Remove managed infrastructure:

    terraform destroy

IMPORTANT:

terraform state rm and terraform state push
change Terraform state and should be used carefully.

terraform state mv with local state file arguments
must be planned separately from backend migration.

## 19. Real-World DevOps Relevance

This lesson demonstrates several important skills:

- Understanding Terraform state internals.
- Separating infrastructure ownership.
- Working with Azure Storage remote backends.
- Managing dependencies across independent states.
- Safely migrating infrastructure state.
- Verifying state consistency.
- Protecting state backups.
- Understanding the difference between state operations
  and real infrastructure changes.

These concepts are useful when splitting monolithic
Terraform projects into smaller, independently
managed infrastructure components.

## 20. Final Summary

Original:

    dev.tfstate
        8 resources

After migration:

    dev-networking.tfstate
        7 resources

    dev-compute.tfstate
        1 resource

Compute reads the networking app_subnet_id output.

Both migrated configurations were validated successfully.

The original state was retired after backup.

The deployed Azure resources were later destroyed,
while the backend infrastructure was preserved.

The key lesson:

Terraform state defines which configuration tracks
and manages an infrastructure resource.

Separating state changes ownership and lifecycle
boundaries without necessarily changing the
underlying infrastructure.
