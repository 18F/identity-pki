# Continuous Integration (CI) VPC

We currently have a Dedicated CI (Continuous Integration) VPC for our
integration tests.

This includes our [Instance Tests](instances.md) and some of our [Chef Cookbook
Tests](cookbooks.md) that must run in AWS.

The idea here is that this VPC includes only the base infrastructure needed to
run the integration tests, and is not a full production environment.  For
example, it currently includes RDS and Elasticache, but should also include an
ELK stack since those are all things we need to test the application instances.

It is configured in exactly the same way as any other environment, and you can
find the current configuration in
[identity-devops-private](https://github.com/18F/identity-devops-private/blob/master/env/ci.sh).
