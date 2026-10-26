# Lesson 13 – Terraform Lifecycle & Dependencies

## 1. Objective

The goal of this lesson was to understand how Terraform controls
resource creation, modification, replacement and destruction.

We tested five important concepts:

1. prevent_destroy
2. create_before_destroy
3. ignore_changes
4. depends_on
5. replace_triggered_by

All exercises used the built-in terraform_data resource.

No Azure infrastructure was required, so the lab did not
generate Azure resource costs.

## 2. Lab Environment

The lab was created in:

    terraform-modules/
        |
        +-- environments/
                |
                +-- lifecycle-lab/
                        |
                        +-- main.tf

The configuration required Terraform version 1.5.0 or newer.

    terraform {
      required_version = ">= 1.5.0"
    }

We used terraform_data because it allows us to experiment
with Terraform lifecycle behavior without creating cloud resources.

## 3. What Is a Lifecycle Block?

The lifecycle block is a Terraform resource meta-argument.

It changes how Terraform handles certain resource operations.

Example:

    resource "terraform_data" "example" {
      input = "example"

      lifecycle {
        prevent_destroy = true
      }
    }

Lifecycle settings do not replace Terraform's normal
dependency and state management.

They influence specific parts of resource behavior.

## 4. prevent_destroy

### Purpose

prevent_destroy protects a resource against destruction
while the protection rule remains in its configuration.

Example:

    resource "terraform_data" "important" {
      input = "important-production-resource"

      lifecycle {
        prevent_destroy = true
      }
    }

### What We Tested

We created a terraform_data resource with prevent_destroy enabled.

Then we executed:

    terraform destroy

Terraform rejected the operation.

The error included:

    Error: Instance cannot be destroyed

### Why?

Terraform detected that the plan required destroying
a resource protected by prevent_destroy.

The lifecycle rule prevented Terraform from generating
a valid destruction plan.

### Important Limitation

prevent_destroy is not an Azure resource lock.

It is a Terraform configuration rule.

If the resource block is removed from configuration,
the protection rule is also removed.

Therefore, prevent_destroy is not an absolute guarantee
against deletion.

### Real-World Usage

Possible examples include:

- Important production databases
- Critical storage resources
- Infrastructure that should not be casually replaced
- Resources requiring a separate deletion approval process

Production protection should also use appropriate
cloud-level controls and access permissions.

## 5. Removing prevent_destroy

During our lab, we removed the lifecycle block.

We used a sed command to delete the block from main.tf.

The command was:

    sed -i '/  lifecycle {/,/  }/d' main.tf

Explanation:

sed:
A command-line stream editor.

-i:
Modifies the file directly.

'/  lifecycle {/,/  }/':
Selects a range of lines beginning with lifecycle {
and ending with the matching text pattern.

d:
Deletes the selected lines.

IMPORTANT:

This command is suitable only for the simple structure
used in our lab.

It does not understand HCL syntax or nested blocks.

Do not use it blindly on complex Terraform configurations.

After removing the lifecycle block, we ran:

    terraform plan -destroy

Terraform was then able to generate a destruction plan.

This demonstrated that prevent_destroy works only
while the rule is present in the configuration.

## 6. create_before_destroy

### Purpose

Some resource changes require Terraform to replace
an existing resource rather than update it in place.

The default replacement order is usually:

    1. Destroy old resource
    2. Create new resource

With create_before_destroy:

    1. Create new resource
    2. Destroy old resource

Example:

    resource "terraform_data" "important" {
      input            = "important-production-resource"
      triggers_replace = "version-1"

      lifecycle {
        create_before_destroy = true
      }
    }

### Understanding triggers_replace

terraform_data supports the triggers_replace argument.

A change to this argument causes Terraform to replace
the resource instead of updating it in place.

In our lab, adding triggers_replace to an existing
resource caused Terraform to plan a replacement.

The plan showed:

    Plan: 1 to add, 0 to change, 1 to destroy.

The replacement action used:

    +/-

This symbol means:

    Create replacement first
    Destroy old resource afterward

### What Happened During Apply?

Terraform created the new resource first.

Afterward, it destroyed the previous resource instance.

The old resource was temporarily marked as a
deposed object while replacement was taking place.

### Real-World Usage

create_before_destroy can help reduce downtime when:

- Replacing infrastructure that supports parallel instances
- Updating resources with immutable attributes
- Deploying replacement infrastructure before removing old resources

### Important Limitations

create_before_destroy does not guarantee zero downtime.

The cloud provider must allow the replacement resource
to exist alongside the old one.

For example, a resource with a globally unique name
may not support parallel creation using the same name.

Dependencies and resource constraints must also
be considered.

## 7. ignore_changes

### Purpose

ignore_changes tells Terraform to ignore changes to
selected resource attributes when planning updates
to an existing resource.

Example:

    resource "terraform_data" "important" {
      input            = "version-1"
      triggers_replace = "version-1"

      lifecycle {
        ignore_changes = [input]
      }
    }

### What We Tested

The existing resource state contained:

    input = "important-production-resource"

The Terraform configuration contained:

    input = "version-1"

Normally, Terraform would detect this difference.

However, we configured:

    ignore_changes = [input]

Terraform reported:

    No changes. Your infrastructure matches the configuration.

### Why?

Terraform was instructed not to plan an update
based on differences in the input attribute.

### Important Detail

ignore_changes applies to update planning.

During initial resource creation, Terraform still
uses the configured attribute values.

### Real-World Usage

ignore_changes may be useful when an attribute
is intentionally managed by another system.

Examples:

- Selected tags managed by an external policy
- Attributes modified by another automation system
- Fields that Terraform should not continuously reconcile

### Risks

Ignoring changes can hide unexpected drift.

For example, if someone modifies a protected
configuration outside Terraform, Terraform may
not correct it.

Use ignore_changes only when there is a clear
ownership reason.

## 8. depends_on

### Purpose

depends_on defines an explicit dependency between
Terraform resources or modules.

Example:

    resource "terraform_data" "network" {
      input = "network-ready"
    }

    resource "terraform_data" "application" {
      input = "application-ready"

      depends_on = [
        terraform_data.network
      ]
    }

### What We Tested

We created two resources:

    terraform_data.network
    terraform_data.application

The application depended on the network.

During apply, Terraform created the network first.

Then Terraform created the application.

The output showed:

    terraform_data.network: Creating...
    terraform_data.network: Creation complete

    terraform_data.application: Creating...
    terraform_data.application: Creation complete

### Why?

The depends_on block told Terraform that the
application must wait for the network dependency.

### Implicit vs Explicit Dependencies

Terraform normally detects dependencies through references.

Example:

    subnet_id = azurerm_subnet.application.id

This creates an implicit dependency.

Terraform knows that the subnet must exist before
the dependent resource can use its ID.

An explicit depends_on is useful when the dependency
cannot be expressed through normal attribute references.

### Important Detail

depends_on does not automatically replace a resource
when its dependency changes.

It primarily controls dependency ordering.

## 9. replace_triggered_by

### Purpose

replace_triggered_by forces replacement of a resource
when a referenced managed resource or attribute changes.

Example:

    resource "terraform_data" "network" {
      input = "network-ready"
    }

    resource "terraform_data" "application" {
      input = "application-ready"

      depends_on = [
        terraform_data.network
      ]

      lifecycle {
        replace_triggered_by = [
          terraform_data.network
        ]
      }
    }

### What We Wanted to Test

We wanted the application to be replaced whenever
the network resource changed.

The application itself would keep the same input value.

### First Attempt

Initially, we changed the network input:

    network-ready -> network-updated

Terraform showed:

    Plan: 0 to add, 1 to change, 0 to destroy.

Only the network was updated.

The application was not replaced.

### Troubleshooting the Result

We inspected main.tf:

    cat main.tf

We discovered that the application contained depends_on,
but the replace_triggered_by lifecycle block was missing.

Therefore, Terraform behaved correctly.

depends_on alone does not trigger replacement.

### Fixing the Configuration

We added:

    lifecycle {
      replace_triggered_by = [
        terraform_data.network
      ]
    }

Then we changed the network input again:

    network-updated -> network-version-3

We executed:

    terraform plan

Terraform now reported:

    terraform_data.application will be replaced
    due to changes in replace_triggered_by

The plan showed:

    Plan: 1 to add, 1 to change, 1 to destroy.

### Understanding the Result

Network:

    ~ update in-place

Application:

    -/+ destroy and then create replacement

The network was updated without being recreated.

The application was replaced because its lifecycle
rule referenced the changing network resource.

The application's own input remained unchanged.

### Important Difference

depends_on:

    Wait for another resource.

replace_triggered_by:

    Replace this resource when the referenced
    managed resource or attribute changes.

### Real-World Usage

replace_triggered_by may be useful when a change
to one managed resource requires recreating another.

For example, a Terraform-managed deployment resource
might need replacement when a tracked application
artifact version changes.

The exact behavior depends on the provider and resource.

### Important Limitation

Replacement is not the same as an application restart.

Terraform may destroy and recreate infrastructure.

This can cause downtime or data loss depending on
the resource type.

Use replace_triggered_by only when replacement
is actually required.

## 10. Understanding Terraform Plan Symbols

During this lesson, we encountered several symbols.

    + create

Terraform will create a new resource.

    - destroy

Terraform will destroy an existing resource.

    ~ update in-place

Terraform will modify an existing resource.

    -/+ destroy and then create replacement

Terraform will destroy the old resource first,
then create its replacement.

    +/- create replacement then destroy

Terraform will create the replacement first,
then destroy the previous instance.

These symbols are important when reviewing
infrastructure changes before apply.

## 11. Comparing Lifecycle and Dependency Features

prevent_destroy:

    Blocks planned destruction while the rule exists.

create_before_destroy:

    Changes the replacement order.

ignore_changes:

    Ignores selected attribute differences during updates.

depends_on:

    Defines an explicit dependency.

replace_triggered_by:

    Forces replacement when a referenced managed
    resource or attribute changes.

Each feature solves a different problem.

They should not be treated as interchangeable.

## 12. Terraform Commands Used

Initialize a Terraform configuration:

    terraform init

Check formatting:

    terraform fmt

Validate configuration:

    terraform validate

Preview changes:

    terraform plan

Apply changes:

    terraform apply

Preview resource destruction:

    terraform plan -destroy

Destroy resources:

    terraform destroy

Inspect the configuration:

    cat main.tf

Change text in a file:

    sed -i 's/old-value/new-value/' main.tf

IMPORTANT:

Review all file modifications and Terraform plans
before applying changes.

## 13. Lab Cleanup

After successfully testing replace_triggered_by,
we ran:

    terraform destroy

Terraform planned to destroy:

    terraform_data.application
    terraform_data.network

The plan showed:

    Plan: 0 to add, 0 to change, 2 to destroy.

After confirmation, Terraform reported:

    Destroy complete! Resources: 2 destroyed.

The lifecycle lab was successfully cleaned up.

No Azure resources were created during this lesson.

## 14. Real-World DevOps Relevance

Lifecycle configuration is important because
infrastructure changes can have serious consequences.

Examples include:

- Accidental deletion of production resources
- Unexpected replacement of critical infrastructure
- Downtime during resource recreation
- Drift caused by external systems
- Incorrect dependency ordering
- Unnecessary resource replacement

A DevOps engineer should always understand
the actions shown in terraform plan.

In production, a plan showing resource replacement
deserves special attention.

## 15. Key Takeaways

1. prevent_destroy protects against planned destruction
   while the lifecycle rule remains configured.

2. create_before_destroy changes the order of replacement.

3. ignore_changes prevents selected differences from
   triggering updates to existing resources.

4. depends_on controls explicit dependencies.

5. replace_triggered_by forces resource replacement
   when a referenced managed resource changes.

6. Terraform plan symbols explain the type and order
   of proposed resource operations.

7. Resource replacement may cause downtime.

8. Lifecycle rules must be used deliberately.

9. Inspect the actual Terraform configuration when
   observed behavior differs from expectations.

10. Always review terraform plan before terraform apply.
