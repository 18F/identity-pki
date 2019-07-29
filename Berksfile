source 'https://api.berkshelf.com'

cookbook 'application_ruby', '~> 4.0.1'
cookbook 'apt', '~> 7.0'
cookbook 'bash-completion'
cookbook 'build-essential', '~> 8.0'
cookbook 'cacert'
cookbook 'git'
cookbook 'hostname'
cookbook 'letsencrypt', '~> 1.0.0'
cookbook 'monit'
cookbook 'motd'
cookbook 'newrelic_meetme_plugin'
cookbook 'ntp'
cookbook 'ohai'
cookbook 'openssl'
cookbook 'ssh-keys'
cookbook 'sudo'
cookbook 'users'
cookbook 'jenkins', '~> 5.0.1'
cookbook 'apache2', '~> 5.2'
cookbook 'runit', '~>4.3.1'
cookbook 'filebeat', '~> 2.1.0'
cookbook 'elasticsearch-curator', '~> 0.3.0'
cookbook 'elasticsearch', '~> 4.0.3'
cookbook 'ossec', '~> 1.2.0', git: 'https://github.com/sous-chefs/ossec'

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
cookbook 'identity-outboundproxy', path: prefixed('kitchen/cookbooks/identity-outboundproxy')
cookbook 'aws_metadata', path: prefixed('kitchen/cookbooks/aws_metadata')
cookbook 'aws_s3', path: prefixed('kitchen/cookbooks/aws_s3')
cookbook 'canonical_hostname', path: prefixed('kitchen/cookbooks/canonical_hostname')
cookbook 'chef_proxy_env', path: prefixed('kitchen/cookbooks/chef_proxy_env')
cookbook 'config_loader', path: prefixed('kitchen/cookbooks/config_loader')
cookbook 'identity-elk', path: prefixed('kitchen/cookbooks/identity-elk')
cookbook 'identity-jenkins', path: prefixed('kitchen/cookbooks/identity-jenkins')
cookbook 'identity-jumphost', path: prefixed('kitchen/cookbooks/identity-jumphost')
cookbook 'identity-nessus', path: prefixed('kitchen/cookbooks/identity-nessus')
cookbook 'identity-pivcac', path: prefixed('kitchen/cookbooks/identity-pivcac')
cookbook 'instance_certificate', path: prefixed('kitchen/cookbooks/instance_certificate')
cookbook 'login_dot_gov', path: prefixed('kitchen/cookbooks/login_dot_gov')
cookbook 'service_discovery', path: prefixed('kitchen/cookbooks/service_discovery')
cookbook 'identity-monitoring', path: prefixed('kitchen/cookbooks/identity-monitoring')

# Cookbooks from our open source github repo
# When updating this gitref, you MUST also run `berks update` and commit
# the changes to Berksfile.lock. Otherwise the old gitref will continue to be
# used by Chef.
IdentityCookbooksRef = 'eee85db18f5a50b26d095b74103b61546c511730'
cookbook 'cloudhsm', '>= 0.0.7', git: 'https://github.com/18F/identity-cookbooks', rel: 'cloudhsm', ref: IdentityCookbooksRef
cookbook 'identity_base_config', git: 'https://github.com/18F/identity-cookbooks', rel: 'identity_base_config', ref: IdentityCookbooksRef
cookbook 'identity_shared_attributes', '>= 0.1.2', git: 'https://github.com/18F/identity-cookbooks', rel: 'identity_shared_attributes', ref: IdentityCookbooksRef
cookbook 'passenger', git: 'https://github.com/18F/identity-cookbooks', rel: 'passenger', ref: IdentityCookbooksRef
cookbook 'static_eip', '>= 0.2.0', git: 'https://github.com/18F/identity-cookbooks', rel: 'static_eip', ref: IdentityCookbooksRef

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
