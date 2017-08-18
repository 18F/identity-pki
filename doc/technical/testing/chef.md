# Testing Chef

## Overview

We have tests at two different levels:

- [Individual Cookbook Tests](cookbooks.md).
- [Full Instance Tests](instances.md).

We have three kinds of tests for our Chef code:

- [ChefSpec](http://sethvargo.github.io/chefspec/) unit tests.
- [Test Kitchen with Vagrant](https://github.com/test-kitchen/kitchen-vagrant).
- [Test Kitchen with EC2](https://github.com/test-kitchen/kitchen-ec2).

Chefspec runs local unit tests, similar to rspec, while Test Kitchen will
actually provision a full instance, either with vagrant or EC2 and run whatever
you configure on that instance.  Our Test Kitchen tests run in a dedicated [CI
VPC](ci-vpc.md).

## Test Kitchen EC2 Prerequisites

To run the test kitchen tests, you need to have an SSH keypair configured in AWS
for test kitchen to use to log in to the instance.

You need two environment variables to be set:

- `KITCHEN_EC2_SSH_KEY`: Path to the ssh key to use to log in.
- `KITCHEN_EC2_SSH_KEYPAIR_ID`: Name of the corresponding keypair in AWS.

For example, if the public key you want to use is at `~/.ssh/id_rsa{.pub}`, run:

```
aws ec2 import-key-pair --key-name MYNAME-SOME-KEY --public-key-material "$(cat ~/.ssh/id_rsa.pub)"
```

And add the following to your environment:

```
export KITCHEN_EC2_SSH_KEYPAIR_ID=MYNAME-SOME-KEY
export KITCHEN_EC2_SSH_KEY=~/.ssh/id_rsa
```

Additionally, these basic ruby tools are good to install:

- Install [ruby-install](https://github.com/postmodern/ruby-install#install)
- Install [chruby](https://github.com/postmodern/chruby#install)
- Install [bundler](http://bundler.io/)

## Test Kitchen Troubleshooting

First, run this to see all the test kitchen options:

```
bundle install && bundle exec kitchen help
```

When there is a test failure, you can run test kitchen with with `-l debug` to
get more debugging output.  I also recommend saving the output to a file, since
it can be very verbose:

```
bundle install && bundle exec env KITCHEN_YAML=.kitchen.cloud.yml kitchen test -l debug | tee debug.log
```

If you would like to reproduce the failure on the test kitchen instance itself,
you can ssh into it using the same key that you [configured test
kitchen to use](chef.md#test-kitchen-prerequisites).

Then, to get the `chef-client` command that test kitchen used to provision the
instance, check the debug output from test kitchen (the normal output
unfortunately doesn't show this):

```
cat debug.log | grep chef-client
```

You can then run this on the instance to reproduce the same `chef-client` run.

If you run into Berkshelf issues, then good luck.  Berkshelf is inconsistent
across versions, has bugs in its resolver, caches things, and has error messages
that have nothing to do with the real issue.  My suggestion is to pare down your
failing example until you have the minimum possible failing test case to try to
isolate the thing that Berkshelf doesn't like.  Fortunately the tests pass now,
so you at least have a starting point of something that works.
