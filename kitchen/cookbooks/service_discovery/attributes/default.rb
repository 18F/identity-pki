# https://help.ubuntu.com/lts/serverguide/certificates-and-security.html
default['service_discovery'] = {}
default['service_discovery']['cert_path'] = '/etc/ssl/certs/server.crt'
default['service_discovery']['cert_bucket_prefix'] = 'login-gov'
