# Azure Monitoring

This lab demonstrates how Azure Monitor collects, routes, analyzes, and reacts to telemetry from Azure resources.

The environment was first explored manually through the Azure Portal and then implemented with Terraform.

The lab covers:

- Guest operating system logs using Azure Monitor Agent and Data Collection Rules
- Azure resource logs using Diagnostic Settings
- Subscription Activity Logs using Diagnostic Settings
- Azure platform metrics
- Metric alerts
- Action Groups
- Email notifications
- Monitoring troubleshooting
- Terraform-based infrastructure lifecycle management

---

## Architecture

```text
                              Azure Monitor
                                   |
              +--------------------+--------------------+
              |                    |                    |
              v                    v                    v
        Guest OS Logs       Azure Platform Logs    Platform Metrics
              |                    |                    |
            Syslog                 NSG             Percentage CPU
              |                    |                    |
              v                    v                    v
             AMA           Diagnostic Settings      Metric Alert
              |                    |                    |
              v                    v                    v
             DCR                  LAW              Action Group
              |                                         |
              v                                         v
             LAW                                      Email
              |
              v
             KQL


Azure Subscription
        |
        v
  Activity Log
        |
        v
Diagnostic Settings
        |
        v
       LAW
        |
        v
 AzureActivity
```

---

## Resources

The Terraform configuration creates the following resources:

- Log Analytics Workspace
- Virtual Network
- Subnet
- Network Security Group
- Public IP address
- Network Interface
- Linux Virtual Machine
- System-Assigned Managed Identity
- Azure Monitor Agent extension
- Data Collection Rule
- Data Collection Rule Association
- NSG Diagnostic Setting
- Subscription Activity Log Diagnostic Setting
- Action Group
- CPU Metric Alert

An existing Azure Resource Group is referenced using a Terraform data source instead of being managed by this configuration.

---

## 1. Log Analytics Workspace

A Log Analytics Workspace is used as the centralized destination for collected log data.

```text
law-monitor-terraform-dev
```

The workspace receives telemetry from multiple sources:

- Linux Syslog
- NSG resource logs
- Azure subscription Activity Logs

This allows different Azure monitoring signals to be queried and analyzed from a central location.

---

## 2. Guest OS Monitoring with AMA and DCR

Linux operating system logs are collected using Azure Monitor Agent (AMA).

The monitoring pipeline is:

```text
Linux Virtual Machine
        |
        v
      Syslog
        |
        v
Azure Monitor Agent
        |
        v
Data Collection Rule
        |
        v
Log Analytics Workspace
        |
        v
    Syslog table
```

The Azure Monitor Agent is installed as a Virtual Machine extension.

The Data Collection Rule defines:

- Which data should be collected
- Which Syslog facilities should be monitored
- Which severity levels should be collected
- Which Log Analytics Workspace should receive the data

A Data Collection Rule Association connects the DCR to the monitored Virtual Machine.

---

## System-Assigned Managed Identity

The Linux Virtual Machine uses a System-Assigned Managed Identity.

This became an important part of the lab during troubleshooting.

Initially, the Azure Monitor Agent service was running successfully:

```text
azuremonitoragent.service
active (running)
```

However, no Syslog records were arriving in Log Analytics.

Inspection of the AMA configuration cache showed that no DCR configuration had been downloaded.

The Virtual Machine was then checked for a Managed Identity, and no identity was configured.

A System-Assigned Managed Identity was added:

```hcl
identity {
  type = "SystemAssigned"
}
```

After enabling the identity, the Azure Monitor Agent successfully downloaded its DCR configuration.

The AMA configuration cache then contained the downloaded configuration.

A new Syslog message was generated:

```bash
logger -p auth.notice "terraform-monitoring-test-after-identity"
```

The message successfully appeared in Log Analytics.

Example query:

```kusto
Syslog
| where SyslogMessage contains "terraform-monitoring-test-after-identity"
| project TimeGenerated, Computer, Facility, SeverityLevel, SyslogMessage
| sort by TimeGenerated desc
```

This verified the complete pipeline:

```text
Linux Syslog
    |
    v
Azure Monitor Agent
    |
    v
Data Collection Rule
    |
    v
Log Analytics Workspace
    |
    v
Syslog table
```

### Troubleshooting Lesson

A running Azure Monitor Agent does not automatically mean that telemetry collection is working.

The troubleshooting process was:

```text
No logs in Log Analytics
        |
        v
Verify AMA service
        |
        | active
        v
Verify log exists locally
        |
        | yes
        v
Inspect AMA configuration cache
        |
        | empty
        v
Check Virtual Machine identity
        |
        | missing
        v
Enable System-Assigned Managed Identity
        |
        v
AMA downloads DCR configuration
        |
        v
Generate new Syslog message
        |
        v
Log appears in Log Analytics
```

This demonstrated the importance of troubleshooting the entire telemetry pipeline instead of checking only whether the monitoring agent is running.

---

## 3. Azure Resource Logs with Diagnostic Settings

Azure resource logs do not require Azure Monitor Agent.

They are generated by the Azure platform.

For this lab, NSG resource logs were configured using Diagnostic Settings.

The following log categories were enabled:

```text
NetworkSecurityGroupEvent
NetworkSecurityGroupRuleCounter
```

The pipeline is:

```text
Network Security Group
        |
        v
Diagnostic Settings
        |
        v
Log Analytics Workspace
```

The Diagnostic Setting configuration was verified successfully through Azure CLI.

Unlike guest OS telemetry, no agent or DCR is required because these logs originate from the Azure platform rather than from inside the operating system.

The Diagnostic Setting was successfully configured, although NSG log ingestion was not used as an end-to-end validation step in this lab.

---

## 4. Azure Activity Log

Azure Activity Log records subscription-level control-plane operations.

Examples include:

- Resource creation
- Resource updates
- Resource deletion
- Policy actions
- Configuration changes

Activity Log exists independently of Log Analytics.

A subscription-level Diagnostic Setting was configured to send Activity Log events to the Log Analytics Workspace.

```text
Azure Subscription
        |
        v
Activity Log
        |
        v
Diagnostic Settings
        |
        v
Log Analytics Workspace
        |
        v
AzureActivity
```

The following Activity Log categories were enabled:

- Administrative
- Security
- ServiceHealth
- Alert
- Recommendation
- Policy
- Autoscale
- ResourceHealth

---

## Activity Log Validation

A control-plane operation was performed against the Network Security Group.

Azure Policy rejected the attempted update.

The Activity Log recorded events including:

```text
Microsoft.Network/networkSecurityGroups/write   Started
Microsoft.Network/networkSecurityGroups/write   Failed
Microsoft.Authorization/policies/deny/action    Failed
```

This demonstrated that failed operations are also useful monitoring and troubleshooting signals.

Activity Log ingestion into Log Analytics was then verified using:

```kusto
AzureActivity
| where TimeGenerated > ago(1h)
| sort by TimeGenerated desc
```

The Log Analytics Workspace successfully contained Azure Activity records.

This verified the pipeline:

```text
Azure Resource Manager operation
        |
        v
Activity Log
        |
        v
Diagnostic Settings
        |
        v
Log Analytics Workspace
        |
        v
AzureActivity
```

---

## 5. Azure Metrics

Azure platform metrics are different from guest operating system logs.

For this lab, the following platform metric was used:

```text
Percentage CPU
```

Azure provides this metric directly for the Virtual Machine.

Because this is a platform metric, Azure Monitor Agent, Data Collection Rules, and Log Analytics are not required for the metric alert.

The flow is:

```text
Virtual Machine
      |
      | Percentage CPU
      v
Azure Monitor Metric
      |
      v
Metric Alert
```

---

## 6. Metric Alert

A Terraform-managed Metric Alert was configured for CPU utilization.

The alert condition was:

```text
Metric:       Percentage CPU
Aggregation:  Average
Operator:     GreaterThan
Threshold:    50%
Window:       5 minutes
Frequency:    1 minute
Severity:     2
```

Conceptually:

```text
Percentage CPU
      |
      v
Average CPU > 50%
      |
      v
Metric Alert
```

The Terraform configuration connects the Metric Alert to the Action Group:

```hcl
action {
  action_group_id = azurerm_monitor_action_group.main.id
}
```

---

## 7. Action Group

An Azure Monitor Action Group was created to define what should happen when the CPU alert fires.

The Action Group contains an email receiver.

```text
Metric Alert
     |
     v
Action Group
     |
     v
Email Notification
```

The email address is provided to Terraform through a sensitive variable rather than being hardcoded into the Terraform configuration.

```hcl
variable "alert_email" {
  description = "Email address that receives Azure Monitor alerts"
  type        = string
  sensitive   = true
}
```

This prevents the email address from being directly stored in the Terraform source code.

---

## 8. Alert Validation

CPU load was generated on the Linux Virtual Machine to test the alert.

Two CPU-intensive processes were started:

```bash
for i in {1..2}; do yes > /dev/null & done
```

CPU utilization increased above the configured 50% threshold.

Azure Monitor evaluated the platform metric and changed the alert state to:

```text
Fired
```

The alert was visible in Azure Monitor with:

```text
Severity:            Sev2
Monitor condition:   Fired
Signal type:         Metric
Monitoring service:  Platform
```

The Action Group also triggered the configured email notification.

This verified the complete alerting pipeline:

```text
Virtual Machine
        |
        | Percentage CPU
        v
Azure Platform Metric
        |
        v
Metric Alert
        |
        | CPU > 50%
        v
      Fired
        |
        v
Action Group
        |
        v
Email Notification
```

---

## Alert Resolution

The CPU load was stopped using:

```bash
pkill yes
```

CPU utilization returned to normal.

After the evaluation window no longer contained CPU utilization above the threshold, Azure Monitor changed the alert condition to:

```text
Resolved
```

A resolved notification was also sent through the Action Group.

The complete alert lifecycle was therefore verified:

```text
Normal CPU
    |
    v
High CPU load
    |
    v
CPU > 50%
    |
    v
Metric Alert
    |
    v
Fired
    |
    v
Action Group
    |
    v
Email Notification
    |
    v
CPU load stopped
    |
    v
CPU returns to normal
    |
    v
Resolved
```

---

## Monitoring Patterns

This lab demonstrates three different telemetry collection patterns and a separate alerting path.

### Guest OS Logs

```text
Linux
  |
  v
AMA
  |
  v
DCR
  |
  v
LAW
```

Used when telemetry originates from inside the operating system.

### Azure Resource and Platform Logs

```text
Azure Resource
      |
      v
Diagnostic Settings
      |
      v
LAW
```

Used for logs generated by Azure resources and services.

### Subscription Activity Log

```text
Azure Subscription
      |
      v
Activity Log
      |
      v
Diagnostic Settings
      |
      v
LAW
```

Used for subscription control-plane activity.

### Platform Metric Alerting

```text
Azure Platform Metric
        |
        v
Metric Alert
        |
        v
Action Group
        |
        v
Notification
```

Used to react to metric conditions such as high CPU utilization.

---

## Key Concepts

### Azure Monitor Agent

Collects supported telemetry from inside the operating system of a monitored machine.

### Data Collection Rule

Defines what telemetry should be collected and where it should be sent.

### Data Collection Rule Association

Associates a Data Collection Rule with the monitored Azure resource.

### Log Analytics Workspace

Central location used to store and query Azure Monitor log data.

### Diagnostic Settings

Routes Azure resource logs and platform logs to destinations such as Log Analytics Workspace.

### Activity Log

Records Azure subscription control-plane operations.

### Metrics

Numerical time-series data generated by Azure resources and services.

### Alerts

Evaluate monitoring signals against defined conditions.

### Action Groups

Define the actions performed when an Azure Monitor alert is triggered.

---

## Terraform Workflow

The infrastructure lifecycle was managed using:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

After deployment, the environment was tested through:

- Linux Syslog generation
- Log Analytics queries
- Azure Activity Log
- Azure Monitor metrics
- CPU load generation
- Metric Alert validation
- Action Group email notifications

After successful validation, all Terraform-managed resources were removed:

```bash
terraform destroy
```

The final Terraform state was verified:

```bash
terraform state list
```

The command returned no managed resources after cleanup.

The existing Resource Group was not destroyed because it was referenced through a Terraform data source rather than managed as a Terraform resource.

---

## Key Lessons Learned

- Azure Monitor contains multiple telemetry paths depending on the source of the data.
- AMA and DCR are used for supported guest operating system telemetry collection.
- Diagnostic Settings route Azure platform and resource logs.
- Activity Log represents subscription control-plane activity.
- Azure platform metrics can be monitored without sending them through Log Analytics.
- Metric Alerts evaluate metric conditions.
- Action Groups define the response to fired alerts.
- A running monitoring agent does not guarantee that telemetry collection is functioning.
- Managed Identity can be an important dependency for Azure Monitor Agent configuration.
- Failed Azure operations can provide valuable Activity Log events for troubleshooting.
- Terraform can manage the monitoring lifecycle from deployment through validation and cleanup.
