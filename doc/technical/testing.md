# How to test `identity-devops` code.

See [our contributor guide](../contributing.md) if you want to submit changes to
this repository.

If you are new here, please start with the [Getting Started
Guide](../getting-started.md).

There are two main parts to the `identity-devops` codebase.

- First, there is Terraform configuration that defines our overall AWS
  Infrastructure.  To test changes to our Terraform configuration, see [Testing
  Terraform](testing/terraform.md).
- Second, there is Chef configuration that defines how individual AWS Instances
  are configured.  To test changes to Chef configuration, see [Testing
  Chef](testing/chef.md).

We also have some initial bootstrap scripts that do some initial configuration
and run chef on an instance using cloud-init.  To test this see [Testing Cloud
Init](../testing/cloud-init.md).
