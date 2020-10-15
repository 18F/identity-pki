# This installs the stuff we need to monitor logstash.
# Run this recipe on elk nodes.

gem_package "elasticsearch" do
  gem_binary node.fetch('login_dot_gov').fetch('rbenv_shims_gem')
end

# TODO remove version pinning once we upgrade the base image to use ruby 2.6
gem_package "ohai" do
  gem_binary node['login_dot_gov']['rbenv_shims_gem']
  version '16.5.6'
end

gem_package "sys-proctable" do
  gem_binary node['login_dot_gov']['rbenv_shims_gem']
end

logstash_health_path = "/#{Chef::Config['file_cache_path']}/logstash_health"

template logstash_health_path do
  mode '0755'
  variables ({
    ruby: node['login_dot_gov']['rbenv_shims_ruby']
  })
end

newrelic_infra_integration 'logstash_health' do
  integration_name 'logstash_health'
  remote_url "file://#{logstash_health_path}"
  install_method 'binary'
  instances(
    [
      {
        name: 'logstash_node_health',
        command: "logstash_health",
        arguments: {
          check: 'node'
        },
        labels: {
          environment: node.chef_environment
        }
      }
    ]
  )
  commands ({
    logstash_health: []
  })
end

logstash_archive_health_path = "/#{Chef::Config['file_cache_path']}/logstash_archive_health"

template logstash_archive_health_path do
  mode '0755'
  variables ({
    ruby: node['login_dot_gov']['rbenv_shims_ruby']
  })
end

newrelic_infra_integration 'logstash_archive_health' do
  integration_name 'logstash_archive_health'
  remote_url "file://#{logstash_archive_health_path}"
  install_method 'binary'
  instances(
    [
      {
        name: 'logstash_archive_health',
        command: "logstash_archive_health",
        arguments: {
          check: 'node'
        },
        labels: {
          environment: node.chef_environment
        }
      }
    ]
  )
  commands ({
    logstash_archive_health: []
  })
end

include_recipe 'newrelic-infra'
