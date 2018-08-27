unless node.fetch('login_dot_gov').fetch('cloudhsm_enabled')
  raise 'Refusing to run cloudhsm config when cloudhsm_enabled is false'
end

cloudhsm_config do
  config_dir '/opt/cloudhsm/etc'
  cluster_id node.fetch('login_dot_gov').fetch('cloudhsm_cluster_id')
  customer_ca_crt node.fetch('login_dot_gov').fetch('cloudhsm_customer_ca')
end
