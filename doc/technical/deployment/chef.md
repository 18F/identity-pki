# Deploying Chef

## Autoscaled Instances

If the instance has an autoscaling group configuration, then see [the Life of an
Instance](../life-of-an-instance.md) documentation for the end to end lifetime
of an autoscaled instance.

See [Recycling Instances](recycling-instances.md) for how to deploy autoscaled
instances.

We also have [administrative tools](tools.md) to directly interact with our AWS
instances should there be a need.

## Terraform Provisioned Instances

We no longer provision instances with terraform directly, but some instances
have not yet been migrated to auto scaling groups, so this still needs to be
documented.

If the instance is provisioned using the terraform chef provisioner, you need to
[use the chef server](../operations/chef-server.md) to manage chef changes.
