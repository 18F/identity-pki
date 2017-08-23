# Environment Configuration

This page describes how to configure various parts of the environment.

For more details on how to configure the cloud-init scripts that run on startup
see the [Recycling Instances Documentation](deployment/recycling-instances.md).

## Terraform

All the variables passed to Terraform should be in `identity-devops-private`.
This will get automatically cloned and sourced by the `deploy` script.

See the
[README](https://github.com/18F/identity-devops-private/blob/59a339a501a13b84ab6077f9c99eec49af1fc862/env/README.md)
for more information, and the [`prod` environment
configuration](https://github.com/18F/identity-devops-private/blob/59a339a501a13b84ab6077f9c99eec49af1fc862/env/prod.sh)
for an example, as of this writing.

## Chef

There is configuration in `identity-devops-private` that tells Terraform which
branch of `identity-devops` and `identity-devops-private` to pass the to the
launch configuration that is used to spin up new instances.

For example [this `dev` environment
configuration](https://github.com/18F/identity-devops-private/blob/c52c0098c0b028f23c52bf4bca8465005b1976cc/env/dev.sh#L42)
in `identity-devops-private` shows that the bootstrap scripts will clone
`identity-devops-private` and checkout the `master` branch, and will clone
`identity-devops` and checkout `stage/dev`.

## Application

Currently the application is configured by Chef attributes.

However this is brittle and causes a lot of extra work:

- https://github.com/18F/identity-devops/pull/524
- https://github.com/18F/identity-devops/pull/519
- https://github.com/18F/identity-devops/pull/430
- https://github.com/18F/identity-devops/pull/427

So there is work in progress to decouple this from the application deployment:
https://github.com/18F/identity-devops-private/issues/230.
