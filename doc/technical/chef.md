# Working with Chef

Currently we deploy a Chef Server in our environment, which all nodes use to
keep their configuration up to date.  This page describes the various management
tasks you might need to do with chef.

### 0. Prerequisites

#### 0.1. Adding a Chef User

If you set up the environment, you should already have a chef user that you
configured during bootstrap.  If someone else set up the environment you are
trying to work with, you may need to get the [config databag
key](https://github.com/18F/identity-private/issues/1825) from them, and create
a new chef user for yourself.

[This
script](https://github.com/18F/identity-devops/blob/master/bin/createchefclient.sh)
is one way to create a chef user, but you can also use
[knife](https://docs.chef.io/knife_user.html).

#### 0.2. Knife/Berkshelf Setup

After your environment is already setup, you can run `bin/setup-knife.sh` and
point it at the jumphost.  If someone else set up the environment you are
trying to work with, you may need to get the [config databag
key](https://github.com/18F/identity-private/issues/1825) from them, and create
a new chef user for yourself.

If knife is set up correctly, `knife node list` on the jumphost should list the
nodes in your env/VPC.

This step is also required to use [Berkshelf](https://berkshelf.com/v2.0/).

### 1. Add/Remove Users and Edit Secret Configuration (Data Bags)

We have data bags for our configuration and our user accounts.  See:
https://github.com/18F/identity-private/wiki/Operations:-Chef-Databags.

During the bootstrap process, these should be added automatically by
https://github.com/18F/identity-devops/blob/master/bin/chef-configuration-first-run.sh.

After you have an environment set up and knife configured correctly, you should
be able to modify the user and config data bags using the `knife data bag`
commands.

For example, to edit the config databag:

```shell
knife data bag edit config app # knife[:secret-file] should be set in your knife.rb
```

### 2. Cookbook, Role, and Environment Configuration Changes

Run `bin/remote-update-chef.sh` to update everything on the chef server to a
given gitref.

### 3. Sync All Nodes with Current Chef Server Configuration (Run chef-client)

To run the `chef-client` you may not need a chef account as long as you have an
account on the box that can sudo.  Just run `sudo chef-client`.

If you want to use `knife ssh` you can use that to run on multiple nodes that
match a pattern without having to manually ssh in.  For example, `knife ssh
'name:*' 'sudo chef-client'` will run chef-client on all nodes.
