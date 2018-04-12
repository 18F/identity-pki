# Testing Application Code

To test application code, run the [Instance Integration Test](instances.md) for
the servers that the application code runs on, in this case, the `idp` and
`worker` servers.

See [Testing Chef](chef.md) for how to set up the prerequisitites to run these
tests.

For quick reference, here's how to run the test (run from the root of
identity-devops):

```
cd nodes/idp && bundle install && bundle exec kitchen test
cd nodes/worker && bundle install && bundle exec kitchen test
```

These will run the integration tests using the currently checked out
`identity-devops` repo you're running them from, and whatever branch of
`identity-idp` the `login_dot_gov.branch_name` attribute specifies in
`kitchen/environments/ci.json`.

If the integration tests pass, [Deploy the Code](../deployment/application.md)
to lower environments and run the [Smoke
Tests](https://github.com/18F/identity-monitor).
