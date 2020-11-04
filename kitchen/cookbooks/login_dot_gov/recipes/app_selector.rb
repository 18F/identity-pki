# check to see if this is the `pt` env
if node.chef_environment == 'pt'
  include_recipe 'login_dot_gov::oidc_sinatra'
else
  include_recipe 'login_dot_gov::dashboard'
end
