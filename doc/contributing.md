# Contributing to Login.gov devops

If you are new here, please start with the [Getting Started
Guide](getting-started.md).  This page documents the process of getting
changes accepted into `identity-devops`.

Look [here](technical/testing.md) for more details on our testing
infrastructure.

## All Changes

- Check out `identity-devops`.
- Make sure [all the tests pass](technical/testing.md).
- If tests are not passing file an issue with the Login.gov team.
- Make your changes and make sure all tests still pass.
- File a pull request against `identity-devops` and labels as `ready for
  review` if you want someone to look at it.

## Chef Cookbook Changes

All Chef Cookbook changes must include the necessary chefspec and/or
integration tests.  See [our testing docs](technical/testing.md) for the current
status of testing.

## Terraform Changes

We do not currently have much testing support, but here are things to consider
testing when making Terraform changes:

- Can you still build an environment from scratch after your changes?
- Can you upgrade an existing environment without downtime?

Eventually, we can add [awsspec](https://github.com/k1LoW/awspec) to test AWS
environment configuration, but we don't yet have a framework for it.  This would
be a welcome contribution!
