# Azure VM Scale Set with Load Balancer and Autoscale

## Overview

This lab demonstrates how to deploy and troubleshoot a highly available Azure Virtual Machine Scale Set (VMSS) using Terraform.

The solution includes:

- Azure Virtual Machine Scale Set
- Availability Zones
- Azure Standard Load Balancer
- Public IP address
- Backend address pool
- HTTP health probe
- Network Security Group
- Nginx deployment using cloud-init
- CPU-based Azure Monitor Autoscale
- Terraform lifecycle management

The lab also includes a real troubleshooting scenario where Autoscale successfully triggered a scale-out operation, but Azure could not provision the additional VM because the subscription reached its regional vCPU quota.

---

## Architecture

```text
                         Internet
                            |
                            v
                  +-------------------+
                  | Public IP         |
                  +-------------------+
                            |
                            v
                  +-------------------+
                  | Standard Load     |
                  | Balancer          |
                  | TCP 80            |
                  +-------------------+
                            |
                     HTTP Health Probe
                            |
                            v
                  +-------------------+
                  | Backend Pool      |
                  +-------------------+
                            |
                            v
                  +-------------------+
                  | VMSS Subnet       |
                  | + NSG             |
                  +-------------------+
                     |             |
                     v             v
                +---------+   +---------+
                | VMSS 0  |   | VMSS 1  |
                | Nginx   |   | Nginx   |
                | Zone 1  |   | Zone 2  |
                +---------+   +---------+

                       Azure Monitor
                            |
                     Percentage CPU
                            |
                            v
                        Autoscale
                       min: 2
                   default: 2
                       max: 4
```

---

## Terraform Resources

The lab provisions the following Azure resources:

- Virtual Network
- Subnet
- Network Security Group
- Subnet-to-NSG association
- Standard Public IP
- Standard Load Balancer
- Load Balancer backend address pool
- HTTP health probe
- Load Balancer rule
- Linux Virtual Machine Scale Set
- Azure Monitor Autoscale setting

An existing Resource Group is referenced using a Terraform data source instead of being created by this lab.

---

## Virtual Machine Scale Set

The VMSS uses:

- Ubuntu 24.04 LTS
- `Standard_D2als_v7`
- 2 initial instances
- Availability Zones 1 and 2
- SSH public-key authentication
- Standard LRS OS disks

Each VMSS instance receives its own network interface from the VMSS network profile and is automatically connected to the Load Balancer backend pool.

---

## Application Deployment

Nginx is installed automatically on every VMSS instance using cloud-init through Terraform `custom_data`.

The startup configuration:

1. Updates package metadata.
2. Installs Nginx.
3. Enables the Nginx service.
4. Starts Nginx.
5. Creates a simple test web page.

Because this configuration belongs to the VMSS model, newly created scale-out instances receive the same application configuration.

The application returns:

```html
<h1>Hello from Azure VMSS</h1>
```

---

## Load Balancing

An Azure Standard Load Balancer exposes the application over TCP port 80.

Traffic flow:

```text
Client
  |
  v
Public IP :80
  |
  v
Standard Load Balancer
  |
  v
Backend Pool
  |
  +----> VMSS Instance 0 :80
  |
  +----> VMSS Instance 1 :80
```

The Load Balancer uses an HTTP health probe:

```text
Protocol: HTTP
Port:     80
Path:     /
```

The health probe verifies that the application is responding before the backend instance receives new traffic.

---

## Network Security Group

During testing, the application was initially unreachable through the Standard Load Balancer even though:

- Both VMSS instances were successfully provisioned.
- Nginx was running.
- Local HTTP requests returned HTTP 200.
- Both VMSS instances were members of the backend pool.
- The Load Balancer rule was correctly configured.
- The health probe was correctly configured.

The missing component was an NSG allowing inbound traffic to the VMSS subnet.

Two inbound rules were added.

### HTTP Traffic

```text
Source:           Internet
Protocol:         TCP
Destination Port: 80
Action:           Allow
```

### Load Balancer Health Probes

```text
Source:           AzureLoadBalancer
Protocol:         TCP
Destination Port: 80
Action:           Allow
```

After associating the NSG with the VMSS subnet, the application became reachable through the Load Balancer public IP.

---

## Autoscale Configuration

Azure Monitor Autoscale manages the runtime VMSS capacity.

### Capacity

```text
Minimum: 2
Default: 2
Maximum: 4
```

### Scale Out

```text
Metric:       Percentage CPU
Condition:    Average CPU > 70%
Time Window:  5 minutes
Action:       Increase instance count by 1
Cooldown:     5 minutes
```

### Scale In

```text
Metric:       Percentage CPU
Condition:    Average CPU < 30%
Time Window:  5 minutes
Action:       Decrease instance count by 1
Cooldown:     5 minutes
```

---

## Autoscale Load Test

CPU load was generated on both VMSS instances.

This was necessary because the Autoscale rule evaluates the average CPU usage of the VMSS.

Generating high CPU load on only one of two instances might not increase the overall average above the configured 70% threshold.

Azure Monitor confirmed sustained CPU usage close to 100%.

Example observed values:

```text
79.23%
99.57%
99.57%
99.57%
99.56%
99.57%
99.57%
```

The Autoscale Activity Log confirmed that Azure attempted to increase the VMSS capacity:

```text
OldInstancesCount: 2
NewInstancesCount: 3
```

This confirmed that:

- CPU metrics were collected correctly.
- The Autoscale rule was evaluated correctly.
- The scale-out threshold was reached.
- Azure initiated the scale-out operation.

---

## Troubleshooting: Autoscale Scale-Out Failure

Although the Autoscale rule triggered correctly, the third VMSS instance could not be provisioned.

Azure Activity Log reported:

```text
Total Regional Cores quota exceeded

Current Limit:        4
Current Usage:        4
Additional Required:  2
Minimum New Limit:    6
```

Each `Standard_D2als_v7` instance uses 2 vCPUs.

Therefore:

```text
2 instances x 2 vCPU = 4 vCPU
3 instances x 2 vCPU = 6 vCPU
```

The subscription had a regional quota of only 4 vCPUs in East US.

The existing two VMSS instances were already consuming the entire regional quota.

The Autoscale configuration itself was therefore working correctly, but Azure could not provision the additional instance because the subscription did not have enough regional vCPU quota.

### Troubleshooting Flow

```text
CPU load generated
        |
        v
Azure Monitor CPU ~99%
        |
        v
Autoscale threshold exceeded
        |
        v
Scale-out triggered
        |
        v
Requested capacity: 2 -> 3
        |
        v
Regional vCPU quota exceeded
        |
        v
Scale-out failed
```

This demonstrates an important operational concept:

> A correctly configured Autoscale rule does not guarantee that a scale operation will successfully provision new infrastructure.

Subscription quotas, regional capacity, Azure Policy, permissions, and other platform constraints can still prevent the requested infrastructure from being created.

---

## Terraform and Autoscale Ownership

The VMSS Terraform configuration defines the initial number of instances:

```hcl
instances = 2
```

Azure Monitor Autoscale can later modify the runtime capacity:

```text
2 -> 3 -> 4 -> 3 -> 2
```

Without additional lifecycle configuration, Terraform could detect a capacity change made by Autoscale as configuration drift.

For example:

```text
Terraform configuration:  instances = 2
Azure runtime capacity:   instances = 3
```

Terraform could then attempt to return the VMSS capacity to 2 during a future apply.

To prevent Terraform from competing with Azure Autoscale, the VMSS resource uses:

```hcl
lifecycle {
  ignore_changes = [instances]
}
```

This establishes clear ownership:

```text
Terraform
    |
    +----> Initial VMSS capacity and infrastructure configuration

Azure Monitor Autoscale
    |
    +----> Runtime VMSS capacity
```

Terraform continues managing the VMSS infrastructure while Azure Monitor Autoscale manages the changing number of instances.

---

## Troubleshooting Tools Used

Several Azure CLI commands were used during troubleshooting.

### Verify VMSS Instances

```bash
az vmss list-instances \
  --resource-group rg-app-dev \
  --name vmss-app-dev \
  --output table
```

### Execute Commands on a VMSS Instance

```bash
az vmss run-command invoke \
  --resource-group rg-app-dev \
  --name vmss-app-dev \
  --instance-id 0 \
  --command-id RunShellScript \
  --scripts "systemctl is-active nginx; curl -I http://localhost"
```

### Inspect Autoscale Configuration

```bash
az monitor autoscale show \
  --resource-group rg-app-dev \
  --name autoscale-vmss-app-dev \
  -o json
```

### Inspect VMSS CPU Metrics

```bash
az monitor metrics list \
  --resource "<VMSS_RESOURCE_ID>" \
  --metric "Percentage CPU" \
  --interval PT1M \
  --aggregation Average \
  -o json
```

### Inspect Autoscale Activity

```bash
az monitor activity-log list \
  --resource-group rg-app-dev \
  --offset 2h \
  --query "[?category.value=='Autoscale']" \
  -o table
```

These commands helped isolate the problem layer by layer instead of assuming that the Autoscale configuration itself was incorrect.

---

## Key Lessons

- VM Scale Sets provide horizontally scalable groups of virtual machines.
- Availability Zones improve resiliency against zone-level failures.
- Azure Standard Load Balancer distributes Layer 4 TCP/UDP traffic.
- Load Balancer health probes determine whether backend instances are healthy.
- NSG rules must allow the required application and Load Balancer probe traffic.
- VMSS `custom_data` can bootstrap every instance with the same application configuration.
- Azure Monitor Autoscale can change VMSS capacity based on metrics such as CPU utilization.
- Autoscale can successfully trigger while the underlying provisioning operation still fails.
- Azure subscription quotas can prevent VMSS scale-out.
- Azure Monitor metrics and Activity Log are important troubleshooting tools.
- Terraform state represents infrastructure managed by a particular Terraform configuration.
- Terraform lifecycle rules can prevent Terraform from competing with runtime controllers such as Azure Autoscale.
- Infrastructure troubleshooting should follow the complete request path rather than immediately assuming that the application or Terraform configuration is incorrect.

---

## Validation Results

| Test | Result |
|---|---|
| Terraform deployment | PASS |
| VMSS instance provisioning | PASS |
| Multi-zone VMSS deployment | PASS |
| Nginx cloud-init deployment | PASS |
| Load Balancer backend membership | PASS |
| HTTP health probe | PASS |
| NSG configuration | PASS |
| Public HTTP connectivity | PASS |
| Azure Monitor CPU metrics | PASS |
| Autoscale rule evaluation | PASS |
| Scale-out trigger from 2 to 3 | PASS |
| Third instance provisioning | BLOCKED BY SUBSCRIPTION QUOTA |

The final scale-out provisioning failure was identified and confirmed through Azure Activity Log diagnostics.

---

## Final Architecture Summary

```text
Internet
   |
   v
Public IP
   |
   v
Azure Standard Load Balancer
   |
   +---- HTTP Health Probe
   |
   v
Backend Pool
   |
   v
VMSS Subnet + NSG
   |
   +-------------------+
   |                   |
   v                   v
VMSS Instance 0    VMSS Instance 1
Zone 1             Zone 2
Nginx              Nginx
   |                   |
   +---------+---------+
             |
             v
       Azure Monitor
       Percentage CPU
             |
             v
          Autoscale
         min 2 / max 4
```
