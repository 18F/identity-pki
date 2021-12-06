unless node.chef_environment == 'prod'
   excluding until we have publicly accessible endpoints and a config that does
   not perform patching and software deployments.
   include_recipe 'identity-soc::bigfix'
   include_recipe 'identity-soc::endgame'
   include_recipe 'identity-soc::fireeye'
end
