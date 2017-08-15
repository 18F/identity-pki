# DevOps Tools

This should document the tools we use in the identity-devops repository.  For
now these docs are a bit scattered and the [getting started
guide](getting-started.md) is a good place to start.

## Administration

These administrative tools are written in ruby and based mostly on querying the
AWS api.

First, use the following two scripts to list running instances:

```
bin/amis-list
bin/ls-servers
```

Then, use the following scripts to SSH into them.  These should automatically
handling proxying through the jumphost, if one is required.

```
bin/cluster-ssh
bin/ssh-instance
```

The `cluster-ssh` script can log into multiple instances at once, while the
`ssh-instance` script is meant to log into a single node.

Run all these scripts with no arguments to show usage.
