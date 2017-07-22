require 'json'

class Chef::Recipe::ConfigLoader
  def self.load_config(node, key)
    if node['integration_test_mode'] == true || node['unittest_mode'] == true
      Chef::DataBagItem.load('config', 'app')[node.chef_environment][key]
    else
      citadel = Citadel.new(node)
      citadel[File.join(node.chef_environment, key)]
    end
  end

  # Like load_config, but designed to handle nested secrets data. If the
  # contents are being loaded from citadel, also JSON.parse the data.
  def self.load_json(node, key)
    if node['integration_test_mode'] == true || node['unittest_mode'] == true
      Chef::DataBagItem.load('config', 'app')[node.chef_environment][key]
    else
      citadel = Citadel.new(node)
      raw = citadel[File.join(node.chef_environment, key)]
      JSON.parse(raw)
    end
  end
end
