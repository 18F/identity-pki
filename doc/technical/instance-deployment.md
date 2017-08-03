# Instance Deployment

There are currently two ways to deploy an instance.  We are attempting to move
to the autoscaled self bootstrapping model from the chef server model.

## Chef Server and Terraform Provisioner

This involves spinning up a chef server using terraform, and using the "chef"
terraform provisioner to configure instances using that chef server.

The steps look like this:

- Run terraform to create a chef server
- Run bin/chef-configuration-first-run.sh to configure the chef server
- Run terraform to create instances using the `aws_instance` resource
  - Terraform will configure chef-client to point at the chef server and run
    chef

## Auto scaled self boostrapping instances

This involves adding cloud-init configuration to the nodes so that they know how
to download `identity-devops` and `identity-devops-private` and run chef-client
against them in local mode.  This allows the instances to be used in autoscaling
groups rather than having them set up directly by terraform.

In this world, configuration and secrets are pulled from github and s3, rather
than from the chef server, so these instances can be deployed standalone.
