#
# Cookbook Name:: instance_certificate
# Attributes:: default
#

# We don't expect any instance to last this long, but this value is a year
# because the risk of outages caused by certificate expiry outweighs having an
# internal self signed certificate that's around for too long.
#
# If the certificate is expired, this cookbook will generate a new one.
default['instance_certificate']['valid_days'] = 365

# https://help.ubuntu.com/lts/serverguide/certificates-and-security.html
default['instance_certificate']['key_path'] = '/etc/ssl/private/server.key'
default['instance_certificate']['cert_path'] = '/etc/ssl/certs/server.crt'
