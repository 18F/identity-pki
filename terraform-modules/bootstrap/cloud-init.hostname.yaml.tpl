#cloud-config

# This file is a terraform template, so be careful with unescaped $ and {}

# These are config files that rely on auto-set-ec2-hostname being installed and
# set to run at startup in the AMI.
# The bootcmd commands get run early in boot, which is important to being able
# to set the hostname before rsyslog and other services start up.
bootcmd:
  - mkdir -vp /etc/auto-hostname
  - 'echo "${hostname_prefix}" > /etc/auto-hostname/prefix'
  - 'echo "${domain}" > /etc/auto-hostname/domain'

preserve_hostname: true

# merge stuff in a sane way with other multipart files
merge_type: 'list(append)+dict(recurse_array)+str()'
