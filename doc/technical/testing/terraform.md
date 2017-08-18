# Testing Terraform

We don't currently have any built in way to test our Terraform code, so this
part is all manual.  Eventually we could use
[kitchen-terraform](https://github.com/newcontext-oss/kitchen-terraform) and
[awspec](https://github.com/k1LoW/awspec) to build automated tests for this as
well.

Given that, here's the recommended workflow for testing terraform changes:

- [Spin up your own VPC](../deployment/terraform.md) using the same
  configuration as the [CI VPC](ci-vpc.md).
  - This should work with a single terraform run, and if it doesn't, file an
    [issue](https://github.com/18F/identity-devops-private/issues/new?labels[]=bug).
- Plan your changes against the [CI VPC](ci-vpc.md) and make sure everything
  looks okay.
- Apply your changes to the [CI VPC](ci-vpc.md).
- Run all the [Instance Tests](instances.md) and [Chef Cookbook
  Tests](cookbooks.md).
- Plan your changes against a real environment (probably dev).
- Apply your changes and make sure everything is running correctly (run smoke
  tests. TODO: link to smoke test documentation).
