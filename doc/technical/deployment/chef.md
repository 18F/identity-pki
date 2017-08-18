# Deploying Chef

## Autoscaled Instances

If the instance has an autoscaling group configuration, then see [the Life of an
Instance](../life-of-an-instance.md) documentation for how to manage this
instance.

The short answer is that if the instances are auto scaled, spinning up new nodes
that point to the gitref that contains your chef changes will cause the new
nodes to be built using that chef code.  You can configure this in
identity-devops-private.  See
[here](https://github.com/18F/identity-devops-private/blob/35db60058663690bb59eb20a225d63da0313a6bd/env/brody.sh#L46)
for an example.

## Terraform Provisioned Instances

We no longer provision instances with terraform directly, but some instances
have not yet been migrated to auto scaling groups, so this still needs to be
documented.

If the instance is provisioned using the terraform chef provisioner, you need to
[use the chef server](../operations/chef-server.md) to manage chef changes.
