# How to test `identity-devops` code.

See [our contributor guide](../contributing.md) if you want to submit changes to
this repository.

## Overview

We have three kinds of tests:

- [ChefSpec](http://sethvargo.github.io/chefspec/) unit tests.
- [Test Kitchen with Vagrant](https://github.com/test-kitchen/kitchen-vagrant).
- [Test Kitchen with EC2](https://github.com/test-kitchen/kitchen-ec2).

Chefspec tests the current cookbook locally and works in a similar way to rspec,
by replacing the plumbing underneath.

Test kitchen tests an entire chef run by provisioning a real instance and
running whatever you configure.  This works in a few stages:

- `create`: Provision the instance, either by creating a vagrant box or an ec2
  instance.
- `converge` and `setup`: SSH into the provisioned instance and run chef-client
  on the instance using the provided run list.
- `verify`: Runs inspec to verify that everything was configured properly.

The kitchen command allows each of these to be run independently, which is
useful for debugging.

We run these tests in two different places:

- Cookbooks: Each cookbook can contain any of these three types of tests,
  depending on which is most appropriate.  These are in the `kitchen/cookbooks`
  directory.
- Nodes: There are per node integration tests.  See
  https://github.com/18F/identity-devops-private/issues/317.  Each of these
  tests should spin up a full node as it would be deployed in our
  infrastructure.  These are in the `nodes` directory.

## Prerequisites

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

## Quick Start

From the root of `identity-devops`:

```
bundle install
bundle exec rake test
```

To list all available rake tasks:

```
bundle install
bundle exec rake -T
```

## To run the ec2 integration tests on a single node

See https://github.com/18F/identity-devops-private/issues/317.

```
cd nodes/jumphost && bundle install && bundle exec env KITCHEN_YAML=.kitchen.cloud.yml kitchen test
```

OR

```
bundle exec rake integration:ec2_nodes[jumphost]
```

Kitchen also has more options if you need to debug the integration tests.  When
you're done you can run `kitchen destroy` to clean up the instance.  Otherwise
if the test fails it will stick around.

## Chef Cookbooks

Currently, we use [ChefSpec](http://sethvargo.github.io/chefspec/) for unit
testing our Chef Cookbooks and [Test
Kitchen](https://github.com/test-kitchen/test-kitchen) for integration tests.

See
https://github.com/18F/identity-devops/tree/master/kitchen/cookbooks/cookbook_example
for an example of a Chef Cookbook that includes both
[Chefspec](https://github.com/sethvargo/chefspec) and [Test
Kitchen](https://github.com/test-kitchen/test-kitchen) tests.  The cookbook
includes examples of using test kitchen with vagrant and ec2 as provisioners.

Code coverage coming soon... https://sethvargo.com/chef-recipe-code-coverage/

## Terraform

Eventually, we want to use
[kitchen-terraform](https://github.com/newcontext-oss/kitchen-terraform), but
we currently don't have a good way to test this besides spinning up a new
environment and testing manually.
