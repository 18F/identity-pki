# This is a bit of a hack, IMHO.
# When we first start up, we cannot complete a full chef run because the
# host isn't on the EIP or pointed to by DNS.  To make it so that terraform
# can complete the chef run and get the EIP up and give us time to make
# DNS point at it, we just run this recipe so that it completes and the
# next time it runs, it has the proper role.

ruby_block 'add_app_role' do
  block do
    node.run_list.delete('recipe[login_dot_gov::install_app_role]')
    node.run_list << 'role[app]'
  end
  only_if { node[:recipes].include?('login_dot_gov::install_app_role') }
end
