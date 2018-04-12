# Chef Cookbook Tests

See the [Testing Chef](chef.md) overview for more background.

There is also an [example
cookbook](https://github.com/18F/identity-devops/tree/master/kitchen/cookbooks/cookbook_example)
that should show how to run these tests.  Make sure to check if that is out of
sync and update that cookbook or these docs if so.

## Running Unit Tests

If cookbook includes a `spec` directory, you can run:

```
bundle install && bundle exec rspec
```

To run the chefspec unit tests.

## Running Integration Tests

If the cookbook includes a `.kitchen.yml` file, you can run:

```
bundle install && bundle exec kitchen test
```

This should run the ec2 integration tests.

## Code Coverage

We don't yet have test coverage, but here is where to start:
https://sethvargo.com/chef-recipe-code-coverage/

## Troubleshooting

See [Test Kitchen Troubleshooting](chef.md#test-kitchen-troubleshooting).
