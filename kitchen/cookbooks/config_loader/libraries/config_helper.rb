class Chef::Recipe::ConfigLoader
  def self.load_config(node, key)
    if node['integration_test_mode'] == true or node['unittest_mode'] == true
      Chef::DataBagItem.load('config', 'app')[node.chef_environment][key]
    else
      citadel = Citadel.new(node)
      citadel[File.join(node.chef_environment, key)]
    end
  end
end
