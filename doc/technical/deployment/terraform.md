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

### Bootstrap Key

The non auto scaled instances are configured by Terraform, and Terraform relies
on early SSH access.  So you need to ask a member of the devops team for the
shared bootstrap key and add it to your `ssh-agent`:

```shell
ssh-add ~/.ssh/login-dev-us-west-2.pem
```

This will allow you to log in as the `ubuntu` user for any instances that are
provisioned using this keypair.

### New Environment

If you're trying to spin up a new environment, run:

```
./bootstrap.sh
```

If this doesn't complete successfully, you'll have to fall back to using the
`deploy` script and manual troubleshooting.

### Special Files

The [Terraform Chef
Provisioner](https://github.com/18F/identity-devops/blob/master/terraform-app/chef.tf#L69)
also creates several files in your `~/.chef` directory:

* `yourusername-<env>.pem`
* `<env>-login-dev-validator.pem`
* `knife-<env>.rb`
* `<env>-databag.key`

These are used to interact with the chef server.  See the [Chef Server
Operations Guide](../operations/chef-server.md) for more details.
