# Tests!

Tests are awesome!  Terratest is cool!  Let's use Terratest to test stuff!

If there is a `tests` dir in the directory that the auto-tf pipeline executes,
the pipeline will cd into it and run `./test.sh`.  So tests will automatically
be run after every deployment.

Technically, you can run any commands in `test.sh`, but that script should
probably mostly just be used to set up environment variables and give different
arguments to the main testing software, which is probably going to be
Terratest:  https://terratest.gruntwork.io/


## Running tests locally

You can run tests locally with 
```
go test -v
```

If your tests rely on AWS creds, you can use aws-vault to run the tests.


## Running tests in codepipeline

The default codepipeline will automatically run `./tests/test.sh` after
doing the terraform plan and apply, and will fail the pipeline run if the
tests fail.

The tests will run with the `auto-terraform` IAM role, so if your test
needs more perms, you will need to add that to the auto-terraform role,
or to create an IAM role that has the permissions it needs, and then
assume that role in the `test.sh` script before running terratest.

## Updating dependencies

We want our tests to be fully contained and not require external resources
to build and run.  To that end, we are vendoring the golang dependencies
in the `tests` dir.

To update that, just say `go mod vendor`, and it should update the
stuff in vendor and let you check it in.  All of the normal go module
stuff should work as well, like `go get -u` and so on.

## Terratest Resources

https://terratest.gruntwork.io/docs/

https://pkg.go.dev/github.com/gruntwork-io/terratest

