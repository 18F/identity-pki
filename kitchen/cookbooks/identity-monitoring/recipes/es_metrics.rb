# This installs the stuff we need to monitor elasticsearch.
# Run this recipe on ES nodes.

gem_package "elasticsearch" do
  gem_binary "#{node.fetch('login_dot_gov').fetch('default_ruby_path')}/bin/gem"
end

es_health_path = "/#{Chef::Config['file_cache_path']}/es_health"

template es_health_path do
  mode '0755'
  variables ({
    :ruby => "#{node.fetch('login_dot_gov').fetch('default_ruby_path')}/bin/ruby"
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

include_recipe 'newrelic-infra'

