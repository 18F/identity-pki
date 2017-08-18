# How to deploy `identity-devops` code.

See [our contributor guide](../contributing.md) if you want to submit changes to
this repository.

If you are new here, please start with the [Getting Started
Guide](../getting-started.md).

There are two main parts to the `identity-devops` codebase.

- First, there is Terraform configuration that defines our overall AWS
  Infrastructure.  To deploy changes to our Terraform configuration, see
  [Deploying Terraform](deployment/terraform.md).
- Second, there is Chef configuration that defines how individual AWS Instances
  are configured.  To deploy changes to Chef configuration, see [Deploying
  Chef](deployment/chef.md).
