class Chef::Recipe::ConfigLoader
  def self.load_config(node)
    # Encrypted data bags don't work yet with integration tests.  See
    # http://atomic-penguin.github.io/blog/2013/06/07/HOWTO-test-kitchen-and-encrypted-data-bags/.
    if node['integration_test_mode'] == true
      Chef::DataBagItem.load('config', 'app')[node.chef_environment]
    else
      Chef::EncryptedDataBagItem.load('config', 'app')[node.chef_environment]
    end
  end
end
