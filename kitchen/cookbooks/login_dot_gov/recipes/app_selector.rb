# check to see if this is the `pt` env
if ['pt', 'pt2'].include?(node.chef_environment)
  include_recipe 'login_dot_gov::oidc_sinatra'
else
  include_recipe 'login_dot_gov::dashboard'
end
