#cloud-config

# boot commands
# default: none
# this is very similar to runcmd, but commands run very early
# in the boot process, only slightly after a 'boothook' would run.
# bootcmd should really only be used for things that could not be
# done later in the boot process.  bootcmd is very much like
# boothook, but possibly with more friendly.
# - bootcmd will run on every boot
# - the INSTANCE_ID variable will be set to the current instance id.
# - you can use 'cloud-init-per' command to help only run once
bootcmd:
# We need to create this using cloud-init as root because:
#   1. We mount `/tmp` noexec, and some cookbooks use `./install.sh` to install
#      packages, which means we need to put the kitchen directory for chef-zero
#      in a different place.
#   2. Test kitchen cannot create the directory because of
#      https://github.com/test-kitchen/test-kitchen/issues/576
 - mkdir /var/lib/kitchen
 - chmod a+w /var/lib/kitchen

# Just mount /tmp exec.  Ran into
# https://github.com/poise/poise-ruby-build/issues/7 during the integration
# test.
# XXX: We should understand why this actually works in our real environment
# since we apparently don't have to do this.
 - mount -o remount,exec,nosuid,nodev /tmp
