#!/bin/bash

# We need to create this using cloud-init as root because:
#   1. We mount `/tmp` noexec, and some cookbooks use `./install.sh` to install
#      packages, which means we need to put the kitchen directory for chef-zero
#      in a different place.
#   2. Test kitchen cannot create the directory because of
#      https://github.com/test-kitchen/test-kitchen/issues/576
mkdir /var/lib/kitchen
chmod a+w /var/lib/kitchen

# Just mount /tmp exec.  Ran into
# https://github.com/poise/poise-ruby-build/issues/7 during the integration
# test.
# XXX: We should understand why this actually works in our real environment
# since we apparently don't have to do this.
mount -o remount,exec,nosuid,nodev /tmp
