# Instance Integration Tests

The purpose of the instance integration tests are to configure an instance in
exactly the way we would configure it when we deploy it, but in a repeatable way
that includes test cases.

Unlike the [Chef Cookbook Tests](cookbooks.md), there is only one kind of
integration test for instances, the test kitchen EC2 integration test.  See the
[Testing Chef](chef.md) overview for more background on how to set this up.

## Running Instance Integration Tests

The instance integration tests are in the `nodes` directory in the
`identity-devops` repo.

To run an integration test for a specific instance, cd into the instance's
directory and run:

```
bundle install && bundle exec kitchen test
```

This should run the ec2 integration tests for that instance.

## Troubleshooting

See [Test Kitchen Troubleshooting](chef.md#test-kitchen-troubleshooting).
