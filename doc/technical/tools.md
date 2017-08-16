# DevOps Tools

This should document the tools we use in the identity-devops repository.  For
now these docs are a bit scattered and the [getting started
guide](getting-started.md) is a good place to start.

## Administration

These administrative tools are written in ruby and based mostly on querying the
AWS api. We have started building AWS libraries in
[/cloudlib](../../cloudlib/).

Run each of these scripts with no arguments to show usage.

### `ls-servers`: list running instances

The `ls-servers` script lets you slice and dice running servers and see
information about them. It filters instances based on queries you provide and
prints a table of information about an EC2 instance (ID, AMI, IP address, etc.).

### `for-servers`: run a command via SSH on many servers

The `for-servers` script makes it easy to run a command across a filtered set
of servers. It filters servers with the same options that `ls-servers` does,
but instead of printing information about the servers, it runs SSH in parallel
threads and runs a specified command on them.

### `ssh-instance`: SSH to an individual server

The `ssh-instance` script is good for connecting via SSH to an individual
server specified by instance ID or instance Name tag (glob pattern). It can run
a command if specified, otherwise it gives an interactive SSH shell.

### `cluster-ssh`: Open interactive SSH terminals in tiled terminal windows

This script uses `ssh-instance` and `cssh` (`csshX` on macOS) to open SSH
terminals in tiled terminal windows all at once. This is useful for highly
interactive sessions where you need to see results across several servers. It
does not scale particularly well to a lot of machines since you run out of
screen space. It's a bit of a hack.

