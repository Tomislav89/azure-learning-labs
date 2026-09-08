# Azure Networking

This section covers Azure networking fundamentals and a hands-on Terraform implementation of a secure Azure network architecture.

The lab demonstrates network segmentation, security controls, custom routing, outbound connectivity, VNet peering, and private access to Azure PaaS services using Private Endpoint and Private DNS.

---

## Architecture Overview

```text
                             Internet
                                ▲
                                │ Outbound
                         ┌──────┴──────┐
                         │ NAT Gateway │
                         │ Static PIP  │
                         └──────┬──────┘
                                │
                         ┌──────▼──────┐
                         │  snet-web   │
                         │ 10.70.1/24  │
                         │    + NSG    │
                         └─────────────┘

                    vnet-tf-networking-dev
                         10.70.0.0/16
          ┌─────────────────┼────────────────────┐
          │                 │                    │
     snet-web           snet-app       snet-private-endpoints
    10.70.1.0/24       10.70.2.0/24        10.70.3.0/24
          │                 │                    │
          │                 │ UDR                │
          │                 ▼                    ▼
          │         10.80.0.0/16 → None    Private Endpoint
          │                                   10.70.3.4
          │                                       │
          │                                       ▼
          │                                Storage Account
          │                             Public access disabled
          │
          │
          └──────── VNet Peering ────────────────┐
                                                 │
                                                 ▼
                                         vnet-peer-tf-dev
                                           10.80.0.0/16
                                                 │
                                            snet-peer
                                           10.80.1.0/24
```

Private DNS integration:

```text
Application
    │
    │ sttfnetworking1212.blob.core.windows.net
    ▼
Azure DNS / Private Link
    │
    ▼
Private DNS Zone
privatelink.blob.core.windows.net
    │
    │ A record
    ▼
sttfnetworking1212 → 10.70.3.4
    │
    ▼
Private Endpoint
    │
    ▼
Azure Blob Storage
```

---

## Technologies Used

- Microsoft Azure
- Terraform
- Azure CLI
- Azure Virtual Network
- Azure Subnets
- Network Security Groups
- User Defined Routes
- NAT Gateway
- Public IP
- VNet Peering
- Azure Storage Account
- Private Endpoint
- Azure Private DNS
- Private Link

---

## Network Design

### Primary Virtual Network

The main network uses the following address space:

```text
vnet-tf-networking-dev
10.70.0.0/16
```

It is segmented into three subnets.

| Subnet | Address Prefix | Purpose |
|---|---|---|
| `snet-web` | `10.70.1.0/24` | Web-tier workloads and controlled outbound Internet access |
| `snet-app` | `10.70.2.0/24` | Application-tier workloads and custom routing |
| `snet-private-endpoints` | `10.70.3.0/24` | Private Endpoints for Azure PaaS services |

Network segmentation allows security and routing policies to be applied independently to different application tiers.

---

## Network Security Group

An NSG is associated with `snet-web`.

The lab includes an inbound rule allowing HTTP traffic:

```text
Source:      Internet
Protocol:    TCP
Port:        80
Action:      Allow
Priority:    100
```

The NSG is associated with the subnet using a dedicated Terraform association resource.

```text
NSG
 │
 ▼
snet-web
```

This demonstrates the separation between creating a security resource and associating it with the network component it protects.

---

## User Defined Routing

A Route Table is associated with `snet-app`.

The following custom route is configured:

```text
Destination: 10.80.0.0/16
Next Hop:    None
```

The `None` next-hop type acts as a blackhole route.

Any traffic originating from `snet-app` and matching `10.80.0.0/16` is dropped.

This route was intentionally created to demonstrate how custom routing can override the expected network path.

---

## NAT Gateway

`snet-web` is associated with an Azure NAT Gateway.

The NAT Gateway uses a static Standard Public IP.

```text
snet-web
    │
    ▼
NAT Gateway
    │
    ▼
Static Public IP
    │
    ▼
Internet
```

This provides predictable outbound Internet connectivity for resources inside the subnet without requiring individual Public IP addresses.

NAT Gateway is used for outbound connectivity and does not provide unsolicited inbound connectivity.

---

## VNet Peering

A second VNet was created:

```text
vnet-peer-tf-dev
10.80.0.0/16
```

with:

```text
snet-peer
10.80.1.0/24
```

Bidirectional VNet peering was configured:

```text
vnet-tf-networking-dev
        │
        │ Peering
        ▼
vnet-peer-tf-dev
```

Both peerings were verified as:

```text
PeeringState:     Connected
PeeringSyncLevel: FullyInSync
```

VNet peering provides private connectivity between Azure VNets over the Azure backbone.

---

## Routing Troubleshooting Scenario

The lab intentionally contains an important routing scenario.

The main VNet is successfully peered with:

```text
10.80.0.0/16
```

However, `snet-app` also has the following UDR:

```text
10.80.0.0/16 → None
```

Therefore:

```text
VNet Peering
Connected
    │
    │
    ▼
Network relationship exists
```

but:

```text
snet-app
    │
    │ Destination: 10.80.0.0/16
    ▼
UDR → None
    │
    ▼
Traffic dropped
```

This demonstrates an important troubleshooting principle:

> A VNet peering state of `Connected` does not guarantee that traffic between workloads will successfully flow.

Effective routes, NSGs, subnet configuration, and destination services must also be inspected.

---

## Private Endpoint

An Azure Storage Account is accessed through a Private Endpoint.

The Private Endpoint is deployed into:

```text
snet-private-endpoints
10.70.3.0/24
```

Azure assigned the Private Endpoint:

```text
10.70.3.4
```

The Private Endpoint targets the Blob subresource of the Storage Account.

```text
VNet
 │
 ▼
Private Endpoint
10.70.3.4
 │
 ▼
Blob Storage
```

This allows the Storage Account to be reached through a private IP inside the VNet.

---

## Private DNS

A Private DNS Zone was created:

```text
privatelink.blob.core.windows.net
```

The zone is linked to:

```text
vnet-tf-networking-dev
```

A Private DNS Zone Group associates the Storage Private Endpoint with the Private DNS Zone.

Azure automatically created the following A record:

```text
sttfnetworking1212 → 10.70.3.4
```

This was verified using Azure CLI.

```bash
az network private-dns record-set a show \
  --resource-group rg-app-dev \
  --zone-name privatelink.blob.core.windows.net \
  --name sttfnetworking1212 \
  --query "aRecords[].ipv4Address" \
  --output tsv
```

Result:

```text
10.70.3.4
```

Applications can continue using the normal Azure Storage hostname:

```text
sttfnetworking1212.blob.core.windows.net
```

while DNS resolution inside the linked VNet directs traffic toward the Private Endpoint.

The application therefore does not need to know or hardcode the Private Endpoint IP address.

---

## Storage Network Security

Public network access to the Storage Account was disabled:

```hcl
public_network_access_enabled = false
```

The intended connectivity model is therefore:

```text
Public network
      │
      X
      │
Storage Account


VNet
 │
 ▼
Private DNS
 │
 ▼
Private Endpoint
 │
 ▼
Storage Account
```

This reduces exposure of the Storage Account and keeps network access on the private path.

---

## Terraform Design

The Terraform configuration is split by responsibility:

```text
terraform/
├── providers.tf
├── variables.tf
├── terraform.tfvars
├── network.tf
├── security.tf
├── routing.tf
├── nat.tf
├── peering.tf
└── private-endpoint.tf
```

The configuration uses variables for environment-specific values such as:

- Azure region
- Resource Group
- VNet names
- VNet address spaces
- Subnet names
- Subnet prefixes
- NSG name
- Route Table name
- NAT Gateway name
- Public IP name
- Storage Account name
- Private Endpoint name
- Common tags

Common tags are applied using:

```hcl
tags = var.tags
```

Example:

```hcl
tags = {
  Environment = "DEV"
  Project     = "AZ-104-Networking"
  ManagedBy   = "Terraform"
}
```

This keeps the infrastructure reusable and reduces unnecessary hardcoding.

---

## Terraform Dependencies

Terraform automatically determines many resource dependencies through references.

For example:

```hcl
virtual_network_name = azurerm_virtual_network.networking.name
```

creates an implicit dependency between the subnet and the VNet.

Similarly:

```hcl
subnet_id = azurerm_subnet.web.id
```

creates a dependency on the subnet.

Explicit `depends_on` is therefore unnecessary when the dependency is already expressed through resource references.

---

## Terraform Workflow

The lab was deployed using the standard Terraform workflow:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

After deployment:

```bash
terraform plan
```

returned:

```text
No changes. Your infrastructure matches the configuration.
```

This confirmed that the Terraform configuration, Terraform state, and deployed Azure infrastructure were synchronized.

Managed resources were inspected using:

```bash
terraform state list
```

---

## Troubleshooting Approach

A useful Azure network troubleshooting workflow is:

```text
1. DNS resolution
       ↓
2. Effective routes
       ↓
3. NSG rules
       ↓
4. Peering / network path
       ↓
5. Destination service
       ↓
6. Application port / protocol
```

Useful Azure tools include:

- Effective Security Rules
- Effective Routes
- IP Flow Verify
- Next Hop
- Connection Troubleshoot
- Azure CLI
- Network Watcher

A successful control-plane configuration does not necessarily guarantee successful data-plane connectivity.

For example:

```text
PeeringState = Connected
```

only confirms that the peering relationship exists.

Traffic can still fail because of:

- User Defined Routes
- NSGs
- DNS configuration
- missing VNet links
- destination firewall rules
- application configuration

---

## Key Concepts Learned

This lab reinforced the following concepts:

- VNet and subnet design
- CIDR-based network segmentation
- NSG rules and subnet associations
- Azure system routes and User Defined Routes
- Longest Prefix Match
- NAT Gateway and outbound connectivity
- VNet Peering
- Private Endpoint
- Azure Private Link
- Private DNS Zones
- DNS A records
- Private DNS VNet Links
- Private DNS Zone Groups
- Storage Account network isolation
- Terraform implicit dependencies
- Terraform state management
- Infrastructure drift detection
- Azure network troubleshooting

---

## Key Takeaways

### NSG vs Routing

```text
Routing:
Where should the traffic go?

NSG:
Is the traffic allowed?
```

Both must permit the intended network flow.

### Private Endpoint vs Private DNS

```text
Private Endpoint
= provides a private network path and private IP

Private DNS
= allows applications to discover that private IP using the service hostname
```

### VNet Peering

```text
Peering Connected
≠
Traffic Guaranteed
```

Routing and security configuration must still allow the traffic.

### NAT Gateway

```text
Private workload
      │
      ▼
NAT Gateway
      │
      ▼
Stable outbound Public IP
      │
      ▼
Internet
```

NAT Gateway does not provide inbound access.

---

## Cleanup

The infrastructure is managed by Terraform and can be removed after the lab to avoid unnecessary Azure costs:

```bash
terraform destroy
```

Always review the destroy plan before confirming.
