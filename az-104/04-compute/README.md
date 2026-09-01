# Azure Compute

## Overview

This section contains hands-on labs and notes covering the core Azure Compute concepts required for AZ-104 and practical Azure administration.

The labs focus on deploying, configuring, scaling, and troubleshooting Azure virtual machine workloads using both the Azure platform and Infrastructure as Code with Terraform.

Topics covered include:

- Azure Virtual Machines
- Virtual machine networking
- Managed disks
- Availability Sets
- Availability Zones
- Virtual Machine Scale Sets
- Azure Load Balancer
- Health probes
- Network Security Groups
- Azure Monitor Autoscale
- Terraform lifecycle management
- Compute troubleshooting
- Azure App Service
- Azure Functions
- Azure Container Instances
- Azure Container Apps
- Azure Kubernetes Service
- Azure Virtual Desktop

---

## Virtual Machine Fundamentals

Azure Virtual Machines provide Infrastructure as a Service (IaaS) compute.

With an Azure VM, Azure manages the physical infrastructure while the customer remains responsible for the guest operating system and workloads running inside it.

Typical customer responsibilities include:

- Operating system configuration
- OS patching
- Application installation
- Application configuration
- Guest OS security
- Filesystem configuration
- Monitoring and troubleshooting

A VM requires supporting infrastructure such as:

```text
Virtual Network
      |
      v
Subnet
      |
      v
Network Interface
      |
      v
Virtual Machine
      |
      +---- OS Managed Disk
      |
      +---- Optional Data Disks
```

---

## Virtual Machine Networking

A Virtual Machine connects to an Azure Virtual Network through a Network Interface Card (NIC).

The NIC receives a private IP address from the subnet.

A Public IP can optionally be associated with the VM network configuration when direct Internet connectivity is required.

Network Security Groups control allowed and denied network traffic.

Example:

```text
Internet
   |
Public IP
   |
  NIC
   |
  NSG
   |
  VM
```

An NSG can be associated with:

- A subnet
- A network interface

---

## Managed Disks

Azure Managed Disks provide persistent block storage for virtual machines.

Common disk types include:

- OS disk
- Data disk
- Temporary disk

Attaching a Managed Disk in Azure does not automatically make it usable inside the guest operating system.

For a new Linux data disk, the typical process is:

```text
Attach Managed Disk
        |
        v
Linux detects block device
        |
        v
Create filesystem
        |
        v
Create mount point
        |
        v
Mount filesystem
        |
        v
Add filesystem UUID to /etc/fstab
        |
        v
Persistent mount after reboot
```

Using the filesystem UUID in `/etc/fstab` is preferred over relying on device names such as `/dev/sdc`, because device names may change.

---

## Availability

### Availability Sets

Availability Sets help protect virtual machines from localized infrastructure failures and planned maintenance.

They use:

- Fault Domains
- Update Domains

Fault Domains separate VMs across underlying hardware infrastructure.

Update Domains help prevent all VMs from being restarted simultaneously during planned platform maintenance.

### Availability Zones

Availability Zones are physically separate locations within an Azure region.

Deploying workloads across multiple zones improves resilience against zone-level failures.

Example:

```text
Azure Region
     |
     +------------------+
     |                  |
     v                  v
Availability Zone 1   Availability Zone 2
     |                  |
    VM1                VM2
     |                  |
     +--------+---------+
              |
              v
        Load Balancer
```

A single VM deployed into one Availability Zone is not highly available by itself.

High availability requires multiple workload instances distributed across failure boundaries.

---

## Virtual Machine Scale Sets

Azure Virtual Machine Scale Sets provide a way to deploy and manage a group of similar virtual machines.

VMSS is useful when applications require:

- Horizontal scaling
- Consistent VM configuration
- Multiple application instances
- Integration with Load Balancer
- Integration with Azure Monitor Autoscale

Example:

```text
                 Load Balancer
                      |
             +--------+--------+
             |                 |
             v                 v
        VMSS Instance 0   VMSS Instance 1
             |                 |
             +--------+--------+
                      |
                   Autoscale
```

All instances are created from the VMSS model, which helps maintain consistent configuration across the workload.

---

## Azure Load Balancer

Azure Load Balancer operates at Layer 4 and distributes TCP or UDP traffic across backend resources.

Typical architecture:

```text
Client
   |
   v
Public IP
   |
   v
Azure Load Balancer
   |
   v
Backend Pool
   |
   +---- VMSS Instance 0
   |
   +---- VMSS Instance 1
```

The Load Balancer does not create or scale virtual machines.

Its responsibility is traffic distribution.

---

## Health Probes

Load Balancer Health Probes determine whether backend instances are healthy enough to receive new traffic.

For a web application, an HTTP probe can check an application endpoint such as:

```text
HTTP
Port 80
Path /
```

If the application stops responding:

```text
Application failure
       |
       v
Health Probe fails
       |
       v
Backend marked unhealthy
       |
       v
Load Balancer stops sending new traffic
```

A VM can therefore be running at the infrastructure level while the application running on it is unhealthy.

---

## Network Security Groups and Load Balancer Traffic

Azure Standard Load Balancer does not automatically allow inbound traffic to backend resources.

The backend network configuration must allow the required traffic.

For the VMSS lab, the subnet NSG allowed:

```text
Internet
   |
TCP 80
   |
VMSS Subnet
```

and Load Balancer health probe traffic:

```text
AzureLoadBalancer
       |
     TCP 80
       |
VMSS Subnet
```

This was required before the application became reachable through the Load Balancer frontend.

---

## Azure Monitor Autoscale

Azure Monitor Autoscale can dynamically modify VMSS capacity based on metrics.

Example:

```text
Minimum: 2
Default: 2
Maximum: 4
```

Scale-out rule:

```text
Average CPU > 70% for 5 minutes
→ Add 1 instance
```

Scale-in rule:

```text
Average CPU < 30% for 5 minutes
→ Remove 1 instance
```

Autoscale changes the runtime capacity of the VMSS while respecting configured minimum and maximum boundaries.

---

## Terraform and Autoscale

Terraform can define the initial VMSS capacity:

```hcl
instances = 2
```

Azure Monitor Autoscale can later change the runtime capacity:

```text
2 → 3 → 4 → 3 → 2
```

Without lifecycle configuration, Terraform may detect Autoscale capacity changes as drift and attempt to restore the value defined in HCL.

To avoid competing ownership:

```hcl
lifecycle {
  ignore_changes = [instances]
}
```

This creates a clear responsibility boundary:

```text
Terraform
   |
   +---- Infrastructure configuration

Azure Monitor Autoscale
   |
   +---- Runtime instance capacity
```

---

## Troubleshooting Approach

Compute troubleshooting should follow the complete request and infrastructure path.

Example:

```text
Client
   |
   v
DNS
   |
   v
Public IP
   |
   v
Load Balancer
   |
   v
Health Probe
   |
   v
Backend Pool
   |
   v
NSG / Routing
   |
   v
VMSS Instance
   |
   v
Application
```

Important troubleshooting sources include:

### Azure Monitor Metrics

Used to investigate workload behavior such as:

- CPU utilization
- Network activity
- Request-related metrics
- Resource performance

### Azure Activity Log

Used to investigate Azure control-plane operations such as:

- Resource creation
- Resource updates
- Autoscale operations
- Failed Azure operations

A useful mental model is:

```text
Metrics
"What happened to the workload?"

Activity Log
"What did Azure try to do?"
```

---

## Real Autoscale Troubleshooting Scenario

During the VMSS lab, CPU load was generated across both VMSS instances.

Azure Monitor showed sustained CPU utilization close to 100%.

The Autoscale rule correctly triggered:

```text
2 instances
     |
     v
3 instances requested
```

However, the scale-out operation failed.

Azure Activity Log identified the root cause:

```text
Total Regional vCPU quota exceeded
```

The VM size used 2 vCPUs per instance.

The subscription regional quota was 4 vCPUs.

Therefore:

```text
2 instances × 2 vCPU = 4 vCPU
3 instances × 2 vCPU = 6 vCPU
```

Autoscale was functioning correctly, but Azure could not provision the additional VM because the subscription had reached its regional compute quota.

This demonstrates that successful Autoscale evaluation does not guarantee successful infrastructure provisioning.

---

## Platform Compute Services

The Compute learning section also covered when to use higher-level Azure compute services.

### Azure App Service

Managed PaaS hosting for web applications and APIs.

Useful when the application does not require operating system level control.

Key capabilities include:

- Managed platform
- Scaling
- Deployment Slots
- HTTPS
- Application hosting without direct OS administration

### Azure Functions

Serverless event-driven compute.

Functions can be triggered by events such as:

- HTTP requests
- Queue messages
- Timers
- Storage events

Hosting selection depends on workload characteristics, including execution frequency and cold-start requirements.

### Azure Container Instances

Useful for simple or short-lived container workloads without requiring container orchestration.

### Azure Container Apps

Managed container platform suitable for APIs, microservices, event-driven workloads, revisions, and autoscaling without directly managing Kubernetes.

### Azure Kubernetes Service

Managed Kubernetes platform for workloads that require Kubernetes APIs, orchestration, Helm, advanced networking, or greater platform control.

---

## Azure Virtual Desktop

Azure Virtual Desktop provides virtualized desktops and applications.

Important concepts include:

### Host Pool

A collection of session host virtual machines.

### Session Host

A virtual machine that accepts user sessions.

### Pooled Host Pool

Multiple users can share session host infrastructure.

### Personal Host Pool

A user receives a dedicated session host.

### RemoteApp

Individual applications can be published without providing users with a complete virtual desktop.

---

## Hands-On Labs

### Terraform VM Infrastructure

Directory:

```text
terraform/
```

Covers foundational Azure VM infrastructure and Terraform resource relationships.

### VMSS, Load Balancer and Autoscale

Directory:

```text
vmss-lab/
```

This lab implements and troubleshoots:

- Multi-zone VMSS
- Nginx deployment using cloud-init
- Standard Load Balancer
- Backend address pool
- HTTP health probe
- NSG configuration
- Azure Monitor Autoscale
- CPU load testing
- Regional vCPU quota failure
- Terraform lifecycle management

See:

```text
vmss-lab/README.md
```

for the complete implementation and troubleshooting walkthrough.

---

## Key Lessons

- Virtual Machines provide OS-level control but require more administration than PaaS services.
- NICs connect VMs to Azure virtual networks.
- Managed data disks require guest OS filesystem and mount configuration.
- Availability Sets and Availability Zones protect against different failure scopes.
- VM Scale Sets provide consistent horizontally scalable VM infrastructure.
- Load Balancer distributes traffic but does not create or scale backend instances.
- Health probes prevent unhealthy application instances from receiving new traffic.
- NSGs must allow the required application and health probe traffic.
- Azure Monitor Autoscale manages runtime VMSS capacity.
- Subscription quota can prevent an otherwise valid scale-out operation.
- Azure Monitor Metrics and Activity Log provide different but complementary troubleshooting information.
- Terraform lifecycle configuration can prevent conflicts with runtime controllers such as Autoscale.
- App Service, Functions, ACI, Container Apps, AKS, and AVD address different compute requirements.
- Troubleshooting should follow the complete request path and isolate one layer at a time.

---

## Status

**Azure Compute: Completed**

The next learning section continues with Azure Networking.
