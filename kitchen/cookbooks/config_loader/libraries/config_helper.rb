require 'json'

class Chef::Recipe::ConfigLoader
  def self.load_config(node, key, common: false)
    if node['integration_test_mode'] == true || node['unittest_mode'] == true
      Chef::DataBagItem.load('config', 'app')[node.chef_environment][key]
    else
      citadel = Citadel.new(node)
      prefix = common ? "common" : node.chef_environment
      citadel[File.join(prefix, key)]
    end
  end

  # Like load_config, but return nil with a warning if Citadel receives an HTTP
  # 404 response code. This only applies to cases where node.chef_environment
  # is not "prod". In the "prod" environment, always raise on errors and never
  # return nil.
  def self.load_config_or_nil(node, key, print_warnings: true)
    load_config(node, key)
  rescue Citadel::CitadelError => err
    if (err.message =~ /Unable to download .*: 404 "Not Found"/ &&
        node.chef_environment != "prod")
      Chef::Log.warn(err.message) if print_warnings
      return nil
    else
      raise
    end
  end

  # Like load_config, but designed to handle nested secrets data. If the
  # contents are being loaded from citadel, also JSON.parse the data.
  def self.load_json(node, key, common: false)
    if node['integration_test_mode'] == true || node['unittest_mode'] == true
      Chef::DataBagItem.load('config', 'app')[node.chef_environment][key]
    else
      citadel = Citadel.new(node)
      prefix = common ? "common" : node.chef_environment
      raw = citadel[File.join(prefix, key)]
      JSON.parse(raw)
    end
  end
end
