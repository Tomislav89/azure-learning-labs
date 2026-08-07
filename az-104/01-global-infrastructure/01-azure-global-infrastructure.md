# Azure Global Infrastructure

## Overview

Microsoft Azure operates through a globally distributed infrastructure consisting of geographies, regions, datacenters, and Availability Zones.

Understanding these concepts is essential when designing systems for availability, latency, compliance, and disaster recovery.

## Azure Geography

An Azure geography is a broad geographical and data residency boundary containing one or more Azure regions.

Geographies help organizations address requirements such as:

- Data residency
- Compliance
- Regulatory requirements
- Service availability

## Azure Region

An Azure region is a physical area containing one or more datacenters connected through a low-latency network.

Examples include:

- West Europe
- North Europe
- Germany West Central
- East US
- East US 2

Many Azure resources require a region to be selected during deployment.

## Availability Zones

Availability Zones are physically separate locations within an Azure region.

Each zone has independent infrastructure such as:

- Power
- Cooling
- Networking

A workload distributed across multiple Availability Zones can remain available when one zone experiences a failure.

Example:

```text
                 Load Balancer
                      │
             ┌────────┴────────┐
             │                 │
      Application VM     Application VM
          Zone 1              Zone 2
```

Simply deploying resources into multiple zones does not automatically provide application failover. The architecture and services must also be configured to support redundancy.

## Region Pairs

Some Azure regions are paired with another region within the same geography.

Region pairing supports aspects of Microsoft's regional resilience strategy.

A Region Pair does **not** automatically replicate an application's infrastructure or data.

Replication must be configured using appropriate services and architecture.

Examples include:

- Geo-redundant storage
- Azure SQL geo-replication
- Azure Site Recovery
- Infrastructure deployment to a secondary region

## High Availability

High Availability focuses on keeping a workload operational during localized infrastructure failures.

Examples include:

- Server failure
- Rack failure
- Availability Zone failure

Common solutions include:

- Multiple application instances
- Availability Zones
- Load balancing
- Zone-redundant Azure services

## Disaster Recovery

Disaster Recovery focuses on recovering or continuing a workload after a major failure.

An example is the loss of an entire Azure region.

A DR architecture may use:

- A secondary Azure region
- Data replication
- Azure Site Recovery
- Backups
- Infrastructure as Code
- DNS or global traffic failover

## High Availability vs Disaster Recovery

```text
High Availability
    │
    └── Protect against localized failures
        within the operating environment

Disaster Recovery
    │
    └── Recover from major failures such as
        loss of an entire region
```

## Interview Questions

1. What is the difference between an Azure geography and an Azure region?
2. What problem do Availability Zones solve?
3. Does a Region Pair automatically replicate Azure resources?
4. What is the difference between High Availability and Disaster Recovery?
5. When would you use Availability Zones instead of a multi-region architecture?

## Key Takeaways

- Geographies provide broad geographical and data residency boundaries.
- Regions contain Azure datacenter infrastructure.
- Availability Zones provide physical separation inside supported regions.
- Availability Zones can protect against localized infrastructure failures.
- Region Pairs do not automatically replicate applications.
- High Availability and Disaster Recovery solve different resilience problems.
