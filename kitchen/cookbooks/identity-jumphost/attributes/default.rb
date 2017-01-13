
# more modern version of terraform
default['terraform']['version'] = '0.8.2'

# allow us to connect to anything
default['squid']['ssl_ports'] = ['1-65535']
default['squid']['safe_ports'] = ['1-65535']

