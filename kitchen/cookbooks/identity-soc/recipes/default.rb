unless node.chef_environment == 'prod'
  include_recipe 'identity-soc::bigfix'
  include_recipe 'identity-soc::endgame'
  include_recipe 'identity-soc::fireeye'
end
