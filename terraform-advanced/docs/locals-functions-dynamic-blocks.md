# Terraform Advanced – Locals, Functions and Dynamic Blocks

## 1. Objective

This lesson explains how Terraform locals, built-in functions,
maps and dynamic blocks help reduce repeated configuration.

Our Azure project uses these concepts to:

- Generate environment-specific resource names.
- Select values based on the environment.
- Store reusable network security rules.
- Generate multiple nested NSG security_rule blocks.

## 2. Local Values

Local values are defined using a locals block.

Our DEV configuration contains:

    locals {
      environment = "DEV"
      name_prefix = "terraform-${lower(local.environment)}"
    }

A local value is referenced using:

    local.environment
    local.name_prefix

Unlike input variables, local values are defined internally
within the Terraform module.

They are useful for calculated values and repeated expressions.

## 3. The lower() Function

Our configuration uses:

    lower(local.environment)

The lower() function converts text to lowercase.

Example:

    local.environment = "DEV"

Result:

    lower(local.environment) = "dev"

The name_prefix expression:

    "terraform-${lower(local.environment)}"

Produces:

    terraform-dev

The resource group uses:

    name = "rg-${local.name_prefix}"

Final name:

    rg-terraform-dev

This helps maintain consistent naming conventions.

## 4. The lookup() Function

Our locals.tf defines:

    vm_sizes = {
      dev  = "Standard_B1s"
      test = "Standard_B2s"
      prod = "Standard_D2s_v5"
    }

    vm_size = lookup(
      local.vm_sizes,
      lower(local.environment),
      "Standard_B1s"
    )

The lookup() function reads a value from a map.

Syntax:

    lookup(map, key, default)

map:
Collection containing key-value pairs.

key:
Value used to find the matching entry.

default:
Value returned when the key is missing.

For DEV:

    lookup(local.vm_sizes, "dev", "Standard_B1s")

Result:

    Standard_B1s

For TEST:

    lookup(local.vm_sizes, "test", "Standard_B1s")

Result:

    Standard_B2s

IMPORTANT:

Our current project calculates local.vm_size but does
not use it to create an Azure virtual machine.

The compute module currently creates only a network interface.

## 5. Maps in Terraform

A map stores values associated with named keys.

Our configuration contains:

    security_rules = {
      http = {
        port = 80
      }

      https = {
        port = 443
      }
    }

This map has two entries:

    http  -> port 80
    https -> port 443

Maps are useful when multiple resources or blocks
share the same structure but use different values.

## 6. Dynamic Blocks

Our Azure networking root configuration contains:

    resource "azurerm_network_security_group" "app" {
      name                = "nsg-app-dev"
      location            = azurerm_resource_group.this.location
      resource_group_name = azurerm_resource_group.this.name

      dynamic "security_rule" {
        for_each = local.security_rules

        content {
          name                       = security_rule.key
          priority                   = security_rule.key == "http" ? 100 : 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = security_rule.value.port
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      }
    }

A dynamic block generates repeated nested blocks
inside a resource.

In this example, Terraform generates two security_rule blocks.

One for HTTP and one for HTTPS.

## 7. Understanding for_each Inside dynamic

The expression:

    for_each = local.security_rules

Iterates over the security_rules map.

During each iteration:

    security_rule.key

Returns the current map key.

Examples:

    http
    https

And:

    security_rule.value.port

Returns the port value.

Examples:

    80
    443

The iterator is named security_rule because that is
the name of the dynamic block.

## 8. Conditional Expressions

Our configuration uses:

    priority = security_rule.key == "http" ? 100 : 110

This is a Terraform conditional expression.

Syntax:

    condition ? true_value : false_value

If the key is http:

    priority = 100

Otherwise:

    priority = 110

For our current map:

    http  -> priority 100
    https -> priority 110

Azure NSG rules require distinct priorities
within the same network security group.

IMPORTANT:

This particular expression is designed for the two
rules currently present in the map.

Adding more rules would require a better priority strategy
to avoid duplicate priorities.

## 9. Resulting NSG Rules

Our dynamic block generates these logical rules:

HTTP:

    name: http
    priority: 100
    direction: Inbound
    access: Allow
    protocol: Tcp
    destination port: 80
    source: *

HTTPS:

    name: https
    priority: 110
    direction: Inbound
    access: Allow
    protocol: Tcp
    destination port: 443
    source: *

Both rules allow inbound traffic from any source.

IMPORTANT SECURITY NOTE:

These rules are examples from a learning lab.

Production network security rules should restrict
source addresses and ports according to application needs.

Also, our current Terraform code creates an NSG
but does not associate it with a subnet or network interface.

Therefore, creating the NSG alone does not enforce
these rules on our subnets or network interface.

## 10. dynamic vs for_each on Resources

Resource-level for_each:

    resource "azurerm_subnet" "this" {
      for_each = var.subnets
    }

Creates multiple Terraform resource instances.

Dynamic block:

    dynamic "security_rule" {
      for_each = local.security_rules
    }

Creates multiple nested blocks within one resource.

This is the main difference.

## 11. Real-World DevOps Usage

Locals and functions are useful for:

- Consistent naming conventions.
- Environment-specific settings.
- Reducing repeated expressions.
- Organizing reusable configuration.
- Simplifying Terraform modules.

Dynamic blocks are useful when a resource needs
a variable number of nested configuration blocks.

However, they should not be used unnecessarily.

Simple static blocks are often easier to read
when the configuration is small and fixed.

## 12. Key Takeaways

1. locals define reusable internal values.
2. lower() converts strings to lowercase.
3. lookup() retrieves map values with a fallback.
4. Maps organize named configuration values.
5. dynamic generates repeated nested blocks.
6. for_each can iterate over maps and collections.
7. Conditional expressions select values based on conditions.
8. Resource for_each and dynamic blocks serve different purposes.
9. Security rules must be reviewed carefully before production use.
10. An NSG must be associated with a subnet or network interface
    before its rules affect network traffic.
