# How to test `identity-devops` code.

See [our contributor guide](contributing.md) if you want to submit changes to
this repository.

## Dependencies

- Install [ruby-install](https://github.com/postmodern/ruby-install#install)
- Install [chruby](https://github.com/postmodern/chruby#install)
- Install [bundler](http://bundler.io/)

## Quick Start

```
rake test
```

## Chef Cookbooks

Currently, we use [ChefSpec](http://sethvargo.github.io/chefspec/) for unit
testing our Chef Cookbooks and [Test
Kitchen](https://github.com/test-kitchen/test-kitchen) for integration tests.

See
https://github.com/18F/identity-devops/tree/master/kitchen/cookbooks/cookbook_example
for an example of a Chef Cookbook that includes both
[Chefspec](https://github.com/sethvargo/chefspec) and [Test
Kitchen](https://github.com/test-kitchen/test-kitchen) tests.

Code coverage coming soon... https://sethvargo.com/chef-recipe-code-coverage/

## Terraform

Eventually, we want to use
[kitchen-terraform](https://github.com/newcontext-oss/kitchen-terraform), but
we currently don't have a good way to test this besides spinning up a new
environment and testing manually.
