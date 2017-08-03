# Structure of this repository.

## `bin` directory

Helper scripts that we use to work with our infrastructure.  See [the tools
documentation](technical/tools.md) for more details.

```
├── bin
│   ├── lib
│   └── oneoffs
```

## `certs` directory

This just contains the letsencrypt certificate chain.  This goes away in
https://github.com/18F/identity-devops/pull/307 since terraform can generate it
for us and we don't need it in this repo.

```
├── certs
```

## `doc` directory

You are here.  Should contain all the technical documentation for the
infrastructure.

```
├── doc
│   ├── process
│   └── technical
```

## `env` directory

Deprecated.  This configuration should now live in
[identity-devops-private](https://github.com/18F/identity-devops-private).

```
├── env
```

## `kitchen` directory

Contains all things chef related.  It's in the structure that chef usually
expects to see on disk, for example when you run chef-zero locally.

```
├── kitchen
```

## `kitchen/cookbooks` directory

Contains all our internal cookbooks.  See [the cookbook structure
documenation](technical/cookbook-structure.md) for how each cookbook is laid
out.

```
├── kitchen
│   ├── cookbooks
│   │   ├── cookbook_example
            ...
```

## `kitchen/data_bags` directory

See https://github.com/18F/identity-private/wiki/Operations:-Chef-Databags for
more details.  These databags represent state on the chef server that cookbooks
can use when they set up instances.

This should all be deprecated.  The secrets are now in citadel as of
https://github.com/18F/identity-devops/pull/428, and the users are in
[identity-devops-private](https://github.com/18F/identity-devops-private).

```
│   ├── data_bags
```

## `kitchen/environments` directory

Chef per environment configuration.  Use this to set per environment node
attributes to control the behavior of cookbooks (in `default_attributes`.  The
package versions in them are ignored and overridden at deploy time.

```
│   ├── environments
```

## `kitchen/nodes` directory

Vestigial.  Ignore this.  This represents the node list stored by chef, but this
is dynamically populated.

```
│   ├── nodes
```

## `kitchen/roles` directory

Chef roles.  These are used to abstract the run list and attributes of specific
node types.  For example `role[base]` contains all the attributes and recipes
that every instance should have, while `role[idp]` contains that plus everything
needed to run the idp server.

```
│   └── roles
```

## `lib` directory

Contains some config file validation that is probably out of date.  Should not
be needed, or moved into the application when
https://github.com/18F/identity-devops-private/issues/230 is done.

```
├── lib
```

## `nodes` directory

Contains integration tests for each node.  These are run using rake from the top
level of `identity-devops`.  Run `rake -T` for more details.

See https://github.com/18F/identity-devops-private/issues/317 for the status of
this.

```
├── nodes
│   └── node_example
        ...
```

## `packer` directory

Contains the packer configuration to build preconfigured AMIs that we can
deploy.  Currently this isn't used in the critical path of anything.

```
├── packer
```

## `terraform-analytics` directory

Contains the terraform configuration for the analytics stack.  See
https://github.com/18F/identity-analytics-etl for more details.

```
├── terraform-analytics
```

## `terraform-app` directory

Contains the terraform configuration for the main login.gov environment.  See
the [getting started guide](/getting-started.md) for more details.

```
├── terraform-app
```

## `terraform-cloudtrail` directory

Contains the terraform configuration for cloudtrail logging.  I have never seen
it used.  I think it's run once per account.

TODO: Better documentation for how to use this.

```
├── terraform-cloudtrail
```

## `terraform-dns` directory

Contains the terraform configuration for the base DNS setup.  I think this is
run once per accounts and configures the main login.gov DNS zone.

TODO: Better documentation for how to use this.

```
├── terraform-dns
```

## `terraform-idp` directory

I believe this is unused and should be deleted.  Contains only secrets bucket
configuration which doesn't match what we actually ended up using for our
secrets storage.

```
├── terraform-idp
```

## `terraform-modules` directory

Directory containing reusable terraform modules for other top level terraform
configuration directories.  These shouldn't be run directory, instead they
should be imported as a module into other terraform configurations.  See
https://www.terraform.io/intro/getting-started/modules.html for more details.

```
└── terraform-modules
    └── version_info
        ...
```
