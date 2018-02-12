source 'https://api.berkshelf.com'

cookbook 'application_ruby', '~> 4.0.1'
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
cookbook 'sysctl'
cookbook 'users'
cookbook 'jenkins', '~> 5.0.1'
cookbook 'apache2'
cookbook 'acme'
cookbook 'terraform', '~ 0.5'
cookbook 'filebeat', '~> 0.4.2'
cookbook 'elasticsearch-curator', '~> 0.1.3'
cookbook 'elasticsearch', '~> 3.0.2'
cookbook 'ossec', '~> 1.0.5', git: 'https://github.com/sous-chefs/ossec'
cookbook 'squid', '~> 3.1', git: 'https://github.com/chef-cookbooks/squid', tag: 'v3.1.2'
#cookbook 'keytool', '~> 0.7.1'
cookbook 'keytool', '~> 0.8.1', git: 'https://github.com/timothy-spencer/chef-keytool', branch: 'tspencer/fix/additionalcreatestor'

# This is a super wacky hack to allow us to symlink this Berksfile into the
# various nodes/*/ directories. It feels like there ought to be a better way to
# do this, e.g. by running `berks -b ../../Berksfile` from test-kitchen, but I
# wasn't able to figure one out.
def prefixed(path)
  unless @prefix
    if File.symlink?(__FILE__)
      # if we're a symlink, figure out the path diff to get to the target
      @prefix = File.dirname(File.readlink(__FILE__))
    else
      @prefix = '.'
    end
  end

  @prefix + '/' + path
end

# Vendored cookbooks. This should include everything in kitchen/cookbooks except for cookbook_example
cookbook 'apt_update', path: prefixed('kitchen/cookbooks/apt_update')
cookbook 'aws_metadata', path: prefixed('kitchen/cookbooks/aws_metadata')
cookbook 'aws_s3', path: prefixed('kitchen/cookbooks/aws_s3')
cookbook 'canonical_hostname', path: prefixed('kitchen/cookbooks/canonical_hostname')
cookbook 'config_loader', path: prefixed('kitchen/cookbooks/config_loader')
cookbook 'identity-elk', path: prefixed('kitchen/cookbooks/identity-elk')
cookbook 'identity-jenkins', path: prefixed('kitchen/cookbooks/identity-jenkins')
cookbook 'identity-jumphost', path: prefixed('kitchen/cookbooks/identity-jumphost')
cookbook 'identity-nessus', path: prefixed('kitchen/cookbooks/identity-nessus')
cookbook 'identity-ntp', path: prefixed('kitchen/cookbooks/identity-ntp')
cookbook 'identity-ossec', path: prefixed('kitchen/cookbooks/identity-ossec')
cookbook 'instance_certificate', path: prefixed('kitchen/cookbooks/instance_certificate')
cookbook 'login_dot_gov', path: prefixed('kitchen/cookbooks/login_dot_gov')
cookbook 'passenger', path: prefixed('kitchen/cookbooks/passenger')
cookbook 'poise-ruby-build', path: prefixed('kitchen/cookbooks/poise-ruby-build')
cookbook 'service_discovery', path: prefixed('kitchen/cookbooks/service_discovery')
cookbook 'identity-monitoring', path: prefixed('kitchen/cookbooks/identity-monitoring')

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
