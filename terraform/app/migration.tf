# Very similar to terraform/app/idp.tf

resource "aws_iam_instance_profile" "migration" {
  name = "${var.env_name}_migration_instance_profile"
  role = module.application_iam_roles.migration_iam_role_name
}

### call for us-east-1 ###

module "migration_us_east_1" {
  providers = {
    aws = aws.use1
  }
  source                           = "../modules/migration_hosts"
  ami_id_map                       = var.ami_id_map
  asg_migration_min                = var.asg_migration_min
  asg_migration_desired            = var.asg_migration_desired
  asg_migration_max                = var.asg_migration_max
  asg_enabled_metrics              = var.asg_enabled_metrics
  autoscaling_time_zone            = var.autoscaling_time_zone
  autoscaling_schedule_name        = var.autoscaling_schedule_name
  base_security_group_id           = aws_security_group.base.id
  bootstrap_private_git_clone_url  = var.bootstrap_private_git_clone_url
  bootstrap_private_git_ref        = var.bootstrap_private_git_ref
  bootstrap_private_s3_ssh_key_url = var.bootstrap_private_s3_ssh_key_url
  bootstrap_main_git_clone_url     = var.bootstrap_main_git_clone_url
  bootstrap_main_git_ref_default   = var.bootstrap_main_git_ref_default
  bootstrap_main_git_ref_map       = var.bootstrap_main_git_ref_map
  bootstrap_main_s3_ssh_key_url    = var.bootstrap_main_s3_ssh_key_url
  chef_download_url                = var.chef_download_url
  chef_download_sha256             = var.chef_download_sha256
  default_ami_id                   = var.default_ami_id
  env_name                         = var.env_name
  fisma_tag                        = var.fisma_tag
  github_ipv4_cidr_blocks          = local.github_ipv4
  instance_type_migration          = var.instance_type_migration
  migration_instance_profile       = aws_iam_instance_profile.migration.name
  migration_rotation_schedules     = local.migration_rotation_schedules
  migration_subnet_ids             = module.network_us_east_1[0].app_subnet_ids
  nessusserver_ip                  = var.nessusserver_ip
  no_proxy_hosts                   = var.no_proxy_hosts
  proxy_enabled_roles              = var.proxy_enabled_roles
  proxy_port                       = var.proxy_port
  proxy_server                     = var.proxy_server
  rails_ami_id_sandbox             = var.rails_ami_id_sandbox
  rails_ami_id_prod                = var.rails_ami_id_prod
  root_domain                      = var.root_domain
  s3_prefix_list_id                = module.network_us_east_1[0].s3_prefix_list_id
  slack_events_sns_hook_arn_use1   = var.slack_events_sns_hook_arn_use1
  vpc_id                           = module.network_us_east_1[0].vpc_id
  vpc_secondary_cidr_block         = module.network_us_east_1[0].secondary_cidr
}