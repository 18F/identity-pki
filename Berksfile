source 'https://api.berkshelf.com'

cookbook 'application_ruby'
cookbook 'apt'
cookbook 'bash-completion'
cookbook 'build-essential'
cookbook 'cacert'
cookbook 'git'
cookbook 'hostname'
cookbook 'letsencrypt', '~> 1.0.0'
cookbook 'monit'
cookbook 'motd'
cookbook 'nano'
cookbook 'newrelic'
cookbook 'newrelic_meetme_plugin'
cookbook 'ntp'
cookbook 'ohai'
cookbook 'openssl'
cookbook 'ruby_rbenv'
cookbook 'poise-ruby'
cookbook 'ruby_build'
cookbook 'ssh-keys'
cookbook 'sudo'
cookbook 'users'
cookbook 'jenkins', '~> 5.0.1'
cookbook 'apache2'
cookbook 'acme'
cookbook 'terraform'
cookbook 'filebeat', '~> 0.4.2'
cookbook 'elasticsearch-curator', '~> 0.1.3'
cookbook 'elasticsearch', '~> 3.0.2'
cookbook 'ossec', '~> 1.0.5', git: 'https://github.com/sous-chefs/ossec'
cookbook 'squid', '~> 3.1', git: 'https://github.com/chef-cookbooks/squid'
#cookbook 'keytool', '~> 0.7.1'
cookbook 'keytool', '~> 0.8.1', git: 'https://github.com/timothy-spencer/chef-keytool', branch: 'tspencer/fix/additionalcreatestor'

cookbook 'login_dot_gov', path: 'kitchen/cookbooks/login_dot_gov'
cookbook 'passenger', path: 'kitchen/cookbooks/passenger'
cookbook 'poise-ruby-build', path: 'kitchen/cookbooks/poise-ruby-build'
cookbook 'identity-jenkins', path: 'kitchen/cookbooks/identity-jenkins'
cookbook 'identity-elk', path: 'kitchen/cookbooks/identity-elk'
cookbook 'identity-jumphost', path: 'kitchen/cookbooks/identity-jumphost'
cookbook 'identity-nessus', path: 'kitchen/cookbooks/identity-nessus'
cookbook 'identity-ossec', path: 'kitchen/cookbooks/identity-ossec'
cookbook 'identity-ntp', path: 'kitchen/cookbooks/identity-ntp'
cookbook 'apt_update', path: 'kitchen/cookbooks/apt_update'
cookbook 'config_loader', path: 'kitchen/cookbooks/config_loader'
cookbook 'aws_metadata', path: 'kitchen/cookbooks/aws_metadata'
cookbook 'aws_s3', path: 'kitchen/cookbooks/aws_s3'
cookbook 'canonical_hostname', path: 'kitchen/cookbooks/canonical_hostname'
cookbook 'instance_certificate', path: 'kitchen/cookbooks/instance_certificate'
cookbook 'service_discovery', path: 'kitchen/cookbooks/service_discovery'

# We have to reference this special citadel-build repository for two reasons:
#
# 1. We have a custom fork of https://github.com/poise/citadel at
#    https://github.com/18f/citadel.git because of
#    https://github.com/poise/citadel/pull/35 and
#    https://github.com/poise/citadel/pull/36.
# 2. There is an extra build step required, and the citadel repository itself is
#    a valid cookbook.  See the citadel-build repository for more details.  This
#    worked before without this extra repo because we were pulling the built
#    citadel from https://supermarket.chef.io.
#
# Once the pull requests are merged and a new citadel version is released we can
# get rid of this.
cookbook 'citadel_fork', '~> 9.1.1', git: 'https://github.com/18f/citadel-build.git'
