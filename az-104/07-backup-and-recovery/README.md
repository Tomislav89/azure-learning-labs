# Azure Backup and Recovery Lab

## Overview

This lab demonstrates how Azure Backup can be used to protect an Azure Linux virtual machine and restore it to a previous point in time.

The lab was completed in two parts:

1. Manual deployment and recovery testing through the Azure Portal.
2. Infrastructure as Code deployment using Terraform.

The goal was to understand both the operational backup and restore workflow and the infrastructure configuration required to enable Azure Backup protection.

---

## Architecture

```text
                    Azure Backup
                         |
                         v
              Recovery Services Vault
                         |
                         v
                   Backup Policy
                         |
                         v
                Protected Linux VM
                         |
                         v
                  Recovery Points
                         |
                         v
                      Restore
```

The Terraform implementation provisions:

```text
Resource Group
|
+-- Virtual Network
|   |
|   +-- Subnet
|       |
|       +-- Network Interface
|           |
|           +-- Linux Virtual Machine
|
+-- Recovery Services Vault
    |
    +-- VM Backup Policy
        |
        +-- Protected Virtual Machine
```

---

## Backup vs Disaster Recovery

Azure Backup and Azure Site Recovery solve different problems.

### Azure Backup

Azure Backup is used to recover data or system state from an earlier point in time.

Typical scenarios include:

- Accidental file deletion
- Data corruption
- Ransomware recovery
- Restoring a virtual machine to an earlier state
- Long-term retention of recovery points

### Azure Site Recovery

Azure Site Recovery is designed for disaster recovery and workload continuity.

It replicates workloads to a secondary location and can fail them over when the primary environment becomes unavailable.

The key distinction is:

```text
Data/state recovery      -> Azure Backup
Workload/site failover   -> Azure Site Recovery
```

A full Site Recovery implementation is intentionally deferred to a larger multi-region enterprise architecture project.

---

## RPO and RTO

### Recovery Point Objective (RPO)

RPO defines how much data loss is acceptable.

Example:

If the latest usable recovery point is 15 minutes old, the effective RPO is approximately 15 minutes.

### Recovery Time Objective (RTO)

RTO defines how long the workload can remain unavailable before service must be restored.

Example:

If the workload must be operational again within one hour, the RTO is one hour.

---

## Recovery Services Vault

A Recovery Services Vault was created to manage Azure Backup protection.

The lab used:

- Standard vault SKU
- Locally redundant storage (LRS)
- Azure secure-by-default soft delete behavior
- Microsoft-managed encryption

The vault acts as the management boundary for backup policies, protected workloads, and recovery points.

---

## Backup Policy

A custom virtual machine backup policy was configured with:

```text
Frequency:                  Daily
Backup time:                22:00 UTC
Daily recovery retention:   7 days
Instant Restore retention:  2 days
```

The backup schedule and backup retention are separate concepts.

The schedule determines when backups are created.

Retention determines how long recovery points remain available.

Instant Restore retention controls how long snapshots are retained for faster recovery.

---

## Portal Backup and Restore Test

A Linux virtual machine was protected using the Recovery Services Vault and the custom backup policy.

The workflow was:

```text
Create Recovery Services Vault
        |
        v
Create Backup Policy
        |
        v
Create Linux VM
        |
        v
Enable Backup Protection
        |
        v
Run Backup Now
        |
        v
Create Recovery Point
        |
        v
Modify VM after backup
        |
        v
Restore recovery point as a new VM
        |
        v
Validate restored state
```

---

## Recovery Point Validation

After the recovery point was created, a file was added to the original virtual machine:

```bash
echo "This file was created AFTER the backup." > ~/after-backup.txt
```

The virtual machine was then restored from the earlier recovery point into a new virtual machine.

On the restored machine:

```bash
ls -l ~/after-backup.txt
```

returned:

```text
No such file or directory
```

This confirmed that the restored OS disk represented the state of the virtual machine at the time the recovery point was created.

Azure Instance Metadata Service was also used to verify that the session was running on the restored Azure resource rather than the original virtual machine.

---

## Backup Consistency

The lab produced a file-system-consistent recovery point.

The main recovery point consistency types are:

### Crash-consistent

Represents disk state similar to an unexpected power loss.

Applications may have incomplete in-memory or pending writes.

### File-system-consistent

The file system is placed into a consistent state before the recovery point is created.

### Application-consistent

Applications participate in the backup process so application data is placed into a consistent state.

For database workloads, application-consistent recovery points are generally preferred when supported by the workload and backup configuration.

---

## Restore Networking Troubleshooting

The restored virtual machine was created successfully but SSH connectivity initially timed out.

The troubleshooting process was:

```text
SSH connection timeout
        |
        v
Check Public IP
        |
        v
Identify restored NIC
        |
        v
Inspect effective NSG rules
        |
        v
No inbound TCP/22 rule
        |
        v
Associate NSG and allow SSH
        |
        v
SSH connectivity restored
```

The important observation was that the restored workload did not automatically reproduce all of the original network access configuration.

This demonstrated why restore validation must include networking and connectivity checks in addition to verifying that the virtual machine itself was successfully created.

For production environments, SSH should not normally be exposed to the entire Internet. Access should be restricted to trusted source addresses or provided through services such as Azure Bastion or private connectivity.

---

## Terraform Implementation

Terraform was used to provision the backup infrastructure and enable protection for a Linux virtual machine.

The primary AzureRM resources were:

```hcl
azurerm_resource_group
azurerm_virtual_network
azurerm_subnet
azurerm_network_interface
azurerm_linux_virtual_machine
azurerm_recovery_services_vault
azurerm_backup_policy_vm
azurerm_backup_protected_vm
```

The key resource connecting the virtual machine to Azure Backup is:

```hcl
resource "azurerm_backup_protected_vm" "backup" {
  resource_group_name = azurerm_resource_group.backup.name
  recovery_vault_name = azurerm_recovery_services_vault.backup.name
  source_vm_id         = azurerm_linux_virtual_machine.backup.id
  backup_policy_id     = azurerm_backup_policy_vm.backup.id
}
```

This is the Infrastructure as Code equivalent of enabling backup protection for the virtual machine through the Azure Portal.

---

## Infrastructure as Code vs Operational Actions

Terraform manages the desired backup configuration:

```text
Recovery Services Vault
        +
Backup Policy
        +
Protected Virtual Machine
```

Operational actions such as:

```text
Backup Now
Restore
File Recovery
Failover
```

are separate from the infrastructure configuration.

They can be initiated through the Azure Portal, Azure CLI, automation, or other operational tooling when required.

This separation is important in real environments:

```text
Terraform
   |
   +-- defines and maintains backup infrastructure

Operational tooling
   |
   +-- performs backup and recovery operations
```

---

## Validation

After `terraform apply`, Terraform reported:

```text
Apply complete! Resources: 8 added, 0 changed, 0 destroyed.
```

Terraform state contained all expected resources, including:

```text
azurerm_backup_policy_vm.backup
azurerm_backup_protected_vm.backup
azurerm_linux_virtual_machine.backup
azurerm_network_interface.backup
azurerm_recovery_services_vault.backup
azurerm_resource_group.backup
azurerm_subnet.backup
azurerm_virtual_network.backup
```

Azure CLI validation confirmed that the virtual machine was registered with the expected backup policy.

Immediately after protection was enabled, the protection state was:

```text
IRPending
```

This indicates that backup protection has been configured but the initial recovery point has not yet been created.

This reinforces an important distinction:

```text
Enable Backup Protection != Recovery Point already exists
```

---

## Terraform Outputs

The Terraform configuration exposes:

```text
backup_policy_name
protected_vm_name
recovery_services_vault_name
resource_group_name
```

Example:

```text
backup_policy_name             = "backup-policy-daily-tf-dev"
protected_vm_name              = "vm-backup-tf-dev"
recovery_services_vault_name   = "rsv-backup-tf-dev"
resource_group_name            = "rg-backup-tf-dev"
```

---

## Security Considerations

Production backup implementations should consider:

- Least-privilege RBAC
- Soft delete
- Backup immutability
- Private connectivity where required
- Restricted administrative access
- Monitoring and alerting for failed backup jobs
- Appropriate storage redundancy
- Recovery testing
- Separation of operational and administrative responsibilities
- Protection against accidental or malicious deletion

Backup configuration alone is not sufficient. Recovery procedures must also be tested.

---

## Cost Considerations

Lab resources were intentionally kept small and temporary.

Cost considerations include:

- Virtual machine compute
- Managed disks
- Backup storage
- Snapshot storage
- Storage redundancy
- Network resources
- Restore-related temporary resources

All temporary resources should be destroyed after validation.

---

## Key Takeaways

- Azure Backup protects workloads using Recovery Services Vaults and backup policies.
- Enabling backup protection does not immediately mean that a recovery point exists.
- Recovery points represent recoverable states from specific points in time.
- Backup schedule and retention are different concepts.
- Instant Restore snapshots can provide faster recovery for recent recovery points.
- Restore testing is necessary to prove that backups are actually usable.
- Restored workloads may require additional network configuration before they are accessible.
- Terraform can declaratively configure backup infrastructure and protection.
- Backup and restore operations are operational actions separate from the Terraform infrastructure lifecycle.
- Azure Backup and Azure Site Recovery solve different recovery problems.
- RPO describes acceptable data loss, while RTO describes acceptable downtime.
