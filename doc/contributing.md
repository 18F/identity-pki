# Contributing to Login.gov devops

If you are new here, please start with the [Getting Started
Guide](doc/getting-started.md).  This page documents the process of getting
changes accepted into `identity-devops`.

Look [here](testing.md) for more details on our testing infrastructure.

## All Changes

- Check out `identity-devops`.
- Make sure [all the tests pass](testing.md).
- If tests are not passing file an issue with the Login.gov team.
- Make your changes and make sure all tests still pass.
- File a pull request against `identity-devops` and labels as `ready for
  review` if you want someone to look at it.

## Chef Cookbook Changes

All Chef Cookbook changes must include the necessary chefspec and/or
integration tests.  See
https://github.com/18F/identity-devops/tree/master/kitchen/cookbooks/cookbook_example
for an example of a Chef Cookbook that includes both
[Chefspec](https://github.com/sethvargo/chefspec) and [Test
Kitchen](https://github.com/test-kitchen/test-kitchen) tests.

## Terraform Changes

We do not currently have much testing support, but here are things to consider
testing when making Terraform changes:

- Can still start an environment from scratch after your changes (see the [Getting Started
Guide](doc/getting-started.md)).
- Can upgrade from the previous version of the environment without downtime.
