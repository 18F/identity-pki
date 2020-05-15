# Deploying Cloud-Init

The Terraform [Boostrap
Module](https://github.com/18F/identity-devops/tree/master/modules/bootstrap)
uses the [Terraform Cloud Init Template
Helpers](https://www.terraform.io/docs/providers/template/d/cloudinit_config.html)
to create the required `user_data` object suitable for passing into an AWS
launch configuration.  You must run an `apply` with the `deploy` script to have
changes in the user data make it into new autoscaled instances.

See [Testing Cloud Init](../testing/cloud-init.md) for how to test changes to
this bootstrap code.
