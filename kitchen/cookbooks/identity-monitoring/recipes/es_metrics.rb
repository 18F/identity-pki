# This installs the stuff we need to monitor elasticsearch.
# Run this recipe on ES nodes.

gem_package "elasticsearch" do
  gem_binary node.fetch('login_dot_gov').fetch('rbenv_shims_gem')
end

# TODO remove version pinning once we upgrade the base image to use ruby 2.6
gem_package "ohai" do
  gem_binary node['login_dot_gov']['rbenv_shims_gem']
  version '16.5.6'
end

es_health_path = "/#{Chef::Config['file_cache_path']}/es_health"

template es_health_path do
  mode '0755'
  variables ({
    ruby: node.fetch('login_dot_gov').fetch('rbenv_shims_ruby')
  })
end

newrelic_infra_integration 'elasticsearch_health' do
  integration_name 'elasticsearch_health'
  remote_url "file://#{es_health_path}"
  install_method 'binary'
  instances(
    [
      {
        name: 'elasticsearch_node_health',
        command: "es_health",
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
    es_health: []
  })
end
