# Recycling Auto Scaled Instances

## Overview

Our AWS auto scaling group launch configuration contains some [cloud-init
scripts](cloud-init.md) that run when an instance is first created and bootstrap
the instance from github (configuration and code) and s3 (secrets).

After the instance is bootstrapped, it should never change.  New secrets will
not be reflected on the instance, and code updates to `identity-idp`,
`identity-devops` and `identity-devops-private` will not be reflected on the
instance.

This means than any change to any code, configuration, or secrets has to be
deployed in exactly the same way: by spinning up new instances that are built
using the new configuration and then spinning down the old instances.

## Configuration

There are a few attributes that control how the application bootstraps itself:

- `identity-devops` and `identity-devops-private` versions are configured in
  `identity-devops-private` and passed into the launch configuration.  This
  tells the cloud init bootstrap scripts which git revisions to check out when
  running the bootstrap `chef-client` runs.
- The `identity-idp` version is configured as a chef attribute, which should be
  in `kitchen/environments/<env_name>.json` in the identity devops version that
  is downloaded.

For example [this `dev` environment
configuration](https://github.com/18F/identity-devops-private/blob/c52c0098c0b028f23c52bf4bca8465005b1976cc/env/dev.sh#L42)
in `identity-devops-private` shows that the bootstrap scripts will clone the
`master` branch of `identity-devops-private`, and the `stages/dev` branch of
`identity-devops`.

As of this writing the [`login_dot_gov.branch_name`
attribute](https://github.com/18F/identity-devops/blob/a2360bf36b71216fd38f24c95df7188ba5bb60ad/kitchen/environments/dev.json#L16)
of the `dev` environment on the `stages/dev` branch of `identity-devops` is set
to `master`.  This means that when an instance does its initial `chef-client`
run against that branch, it will install whatever is on `master` of
`identity-idp`.

See [the Life of an Instance](../life-of-an-instance.md) documentation for the
full end to end process of creating and deploying a new instance.

## How To Recycle Instances

The AWS autoscaling group has a "desired capacity" attribute that specifies how
many instances should be running and healthy.  If AWS spins up that many
instances and they pass the basic health checks, then no more action will be
taken.

Recycling instances involves forcing AWS to create more instances and tear down
the old ones after those are healthy.

This involves a few steps:

1. Double the "desired capacity"
2. Check that the new instances are healthy
3. Cut the "desired capacity" in half

Our auto scaling group is configured to destroy the oldest instances, so this
process will result in only new instances running.

We have a helper script in `identity-devops` called
[`bin/asg-recycle.sh`](https://github.com/18F/identity-devops/blob/master/bin/asg-recycle.sh)
that does this, although it doesn't fully do the check that instances are up and
healthy besides the built in AWS ELB health check for the IDP nodes, so it's not
yet recommended to use this in customer facing environments.

To do this manually, use either the AWS console or the AWS CLI.  See
http://docs.aws.amazon.com/autoscaling/latest/userguide/as-manual-scaling.html.

We also have [administrative tools](tools.md) to directly interact with our AWS
instances to directly troubleshoot or show that they're healthy.
