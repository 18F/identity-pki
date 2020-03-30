
# allow us to connect to anything
default['squid']['ssl_ports'] = ['1-65535']
default['squid']['safe_ports'] = ['1-65535']
# listen on loopback only
default['squid']['listen_interface'] = 'lo'
default['squid']['ipaddress'] = '127.0.0.1'

default['login_dot_gov']['lockdown'] = false

default['identity-jumphost']['ssh-health-check-port'] = 26
# Download SSH host keys from secret store
default['identity-jumphost']['retrieve-ssh-host-keys'] = false

# add locust testing to hosts
default['identity-jumphost']['loadtest']['enabled'] = false
default['identity-jumphost']['loadtest']['branch'] = 'master'
