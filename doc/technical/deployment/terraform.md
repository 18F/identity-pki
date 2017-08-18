# Deploying Terraform

## With Only Autoscaled Instances

If you have no instances that are not in auto scaling groups, then you can run
the `deploy` command from the root of `identity-devops` without any additional
setup.  See the [CI VPC](../testing/ci-vpc.md) configuration for an example of
how to configure an environment to not provision any chef provisioned instances.

Here's a deploy command example:

```
./deploy dev myuser terraform-app plan
# Check plan output
./deploy dev myuser terraform-app apply
```

This should complete successfully.  If it does not, file an
[issue](https://github.com/18F/identity-devops-private/issues/new?labels[]=bug).
This should work for both new and existing environments.

## With Non Autoscaled Instances

If you have non autoscaled instances in your environment, refer back to the
[Getting Started Guide](../../getting-started.md).
