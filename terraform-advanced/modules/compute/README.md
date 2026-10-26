# Terraform Compute Module – Azure Network Interface

## 1. Purpose

This module creates an Azure Network Interface (NIC).

A network interface allows an Azure virtual machine to connect to
a virtual network through a subnet.

IMPORTANT:
This module does NOT create a virtual machine.
It creates only the network interface.

## 2. Project Files

The module contains three Terraform files:

- main.tf: Defines the network interface resource.
- variables.tf: Defines the module input variables.
- outputs.tf: Exposes the network interface ID.

## 3. Understanding main.tf

The module contains:

    resource "azurerm_network_interface" "this" {
      name                = var.nic_name
      location            = var.location
      resource_group_name = var.resource_group_name

      ip_configuration {
        name                          = "internal"
        subnet_id                     = var.subnet_id
        private_ip_address_allocation = "Dynamic"
      }
    }

Explanation:

azurerm_network_interface:
Azure resource type managed by the Terraform AzureRM provider.

this:
Terraform's local name for this resource.

var.nic_name:
Name of the network interface.

var.location:
Azure region where the network interface is created.

var.resource_group_name:
Resource group containing the network interface.

## 4. IP Configuration

The ip_configuration block defines how the network interface
connects to the Azure network.

name = "internal":
Name of the IP configuration.

subnet_id = var.subnet_id:
Specifies which Azure subnet the interface belongs to.

private_ip_address_allocation = "Dynamic":
Azure automatically assigns an available private IP address
from the subnet.

Dynamic allocation does not mean that the IP address changes
every time the resource is used.

## 5. Input Variables

nic_name:
- Type: string
- Purpose: Name of the network interface.

location:
- Type: string
- Purpose: Azure region.

resource_group_name:
- Type: string
- Purpose: Resource group name.

subnet_id:
- Type: string
- Purpose: Azure resource ID of the subnet.

The module does not need to know how the subnet was created.

It only needs a valid subnet ID.

This makes the module reusable.

## 6. Output

The module exposes:

    output "nic_id" {
      description = "ID of the network interface"
      value       = azurerm_network_interface.this.id
    }

The output returns the Azure resource ID of the network interface.

A root Terraform configuration can access it through:

    module.compute.nic_id

Outputs allow other configurations to reference created resources
without manually copying their Azure resource IDs.

## 7. Connecting Networking and Compute

In our project, networking and compute use separate Terraform states.

Networking state:

    dev-networking.tfstate

Compute state:

    dev-compute.tfstate

The networking configuration exposes:

    output "app_subnet_id" {
      value = module.networking.app_subnet_id
    }

The compute configuration reads this value through:

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

The compute module receives the subnet ID using:

    subnet_id = data.terraform_remote_state.networking.outputs.app_subnet_id

Explanation:

data:
Reads information instead of creating infrastructure.

terraform_remote_state:
Reads root outputs from another Terraform state.

networking:
Local name of the remote state data source.

outputs.app_subnet_id:
Output exposed by the networking root configuration.

The compute configuration can therefore use the subnet ID
without managing the networking resources itself.

## 8. Dependency Between Networking and Compute

Our architecture has the following logical dependency:

    Networking infrastructure
             |
             v
       app_subnet_id
             |
             v
      Compute configuration
             |
             v
       Network Interface

Networking must be deployed before compute can create
a network interface inside its subnet.

When destroying the infrastructure, compute should be
destroyed before networking.

This prevents problems caused by attempting to remove
network resources that are still in use.

IMPORTANT:
Separate Terraform states do not automatically create
a single dependency graph across both configurations.

Deployment order must be managed through the workflow
or CI/CD pipeline.

## 9. Terraform Commands

Run commands from the root compute configuration:

    cd environments/dev-separated/compute

    terraform init
    terraform validate
    terraform plan
    terraform apply

terraform init:
Initializes providers and the remote backend.

terraform validate:
Checks the Terraform configuration.

terraform plan:
Shows proposed changes and may read the networking remote state.

terraform apply:
Creates or updates the network interface.

To remove the compute infrastructure:

    terraform destroy

Always inspect the execution plan before confirming.

## 10. Real-World DevOps Usage

Separating networking and compute is useful because:

- Networking can be maintained by a platform team.
- Application teams can manage their own compute resources.
- Different infrastructure components have independent states.
- Changes to compute do not require applying the networking configuration.
- Networking outputs provide reusable infrastructure information.

However, sharing remote state requires appropriate access controls.

Consumers of remote state may require access to the full
underlying state snapshot, not just the exposed outputs.

For stricter isolation, teams can publish required values
through a separate configuration store or another controlled interface.

## 11. Key Takeaways

- A network interface connects compute resources to Azure networking.
- Our compute module creates a NIC, not a virtual machine.
- Variables make the module reusable.
- Outputs expose created resource IDs.
- terraform_remote_state allows one configuration to read
  outputs from another Terraform state.
- Separate states require careful deployment and destruction order.
