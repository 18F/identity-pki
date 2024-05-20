module "outboundproxy_uw2" {
  source = "../modules/outbound_proxy"

  use_prefix                           = false
  external_role                        = module.application_iam_roles.obproxy_iam_role_name
  create_cpu_policy                    = false
  ami_id_map                           = var.ami_id_map_uw2
  asg_outboundproxy_desired            = var.asg_outboundproxy_desired
  asg_outboundproxy_min                = var.asg_outboundproxy_min
  asg_outboundproxy_max                = var.asg_outboundproxy_max
  asg_prevent_auto_terminate           = var.asg_prevent_auto_terminate
  asg_enabled_metrics                  = var.asg_enabled_metrics
  bootstrap_main_git_ref_default       = local.bootstrap_main_git_ref_default
  bootstrap_main_git_ref_map           = var.bootstrap_main_git_ref_map
  bootstrap_main_s3_ssh_key_url        = local.bootstrap_main_s3_ssh_key_url
  bootstrap_main_git_clone_url         = var.bootstrap_main_git_clone_url
  bootstrap_private_git_ref            = local.bootstrap_private_git_ref
  bootstrap_private_s3_ssh_key_url     = local.bootstrap_private_s3_ssh_key_url
  bootstrap_private_git_clone_url      = var.bootstrap_private_git_clone_url
  chef_download_url                    = var.chef_download_url
  chef_download_sha256                 = var.chef_download_sha256
  env_name                             = var.env_name
  root_domain                          = var.root_domain
  default_ami_id                       = local.account_default_ami_id
  slack_events_sns_hook_arn            = var.slack_alarms_sns_hook_arn
  name                                 = var.name
  region                               = var.region
  fisma_tag                            = var.fisma_tag
  instance_type_outboundproxy          = var.instance_type_outboundproxy
  proxy_enabled_roles                  = var.proxy_enabled_roles
  route53_internal_zone_id             = module.internal_dns_uw2.internal_zone_id
  hostname                             = "obproxy.login.gov.internal"
  use_spot_instances                   = var.use_spot_instances
  vpc_id                               = module.network_uw2.vpc_id
  proxy_subnet_ids                     = [for subnet in module.network_uw2.app_subnet : subnet.id]
  base_security_group_id               = module.network_uw2.base_id
  proxy_security_group_id              = module.network_uw2.security_group_id
  proxy_for                            = ""
  ssm_access_policy                    = module.ssm_uw2.ssm_access_role_policy
  s3_secrets_bucket_name               = data.aws_s3_bucket.secrets.bucket
  autoscaling_time_zone                = var.autoscaling_time_zone
  autoscaling_schedule_name            = var.autoscaling_schedule_name
  use_outboundproxy_rotation_schedules = true

  depends_on = [
    module.network_uw2.base_id,
    module.network_uw2.security_group_id
  ]
}

### Outbound Proxy Host in us-east-1 ###

module "outboundproxy_use1" {
  count  = var.enable_us_east_1_infra ? 1 : 0
  source = "../modules/outbound_proxy"
  providers = {
    aws = aws.use1
  }

  use_prefix                           = false
  create_cpu_policy                    = false
  ami_id_map                           = var.ami_id_map_ue1
  asg_outboundproxy_desired            = var.asg_outboundproxy_desired
  asg_outboundproxy_min                = var.asg_outboundproxy_min
  asg_outboundproxy_max                = var.asg_outboundproxy_max
  asg_prevent_auto_terminate           = var.asg_prevent_auto_terminate
  asg_enabled_metrics                  = var.asg_enabled_metrics
  bootstrap_main_git_ref_default       = local.bootstrap_main_git_ref_default
  bootstrap_main_git_ref_map           = var.bootstrap_main_git_ref_map
  bootstrap_main_s3_ssh_key_url        = local.bootstrap_main_s3_ssh_key_url_ue1
  bootstrap_main_git_clone_url         = var.bootstrap_main_git_clone_url
  bootstrap_private_git_ref            = local.bootstrap_private_git_ref
  bootstrap_private_s3_ssh_key_url     = local.bootstrap_private_s3_ssh_key_url_ue1
  bootstrap_private_git_clone_url      = var.bootstrap_private_git_clone_url
  chef_download_url                    = var.chef_download_url
  chef_download_sha256                 = var.chef_download_sha256
  env_name                             = var.env_name
  root_domain                          = var.root_domain
  default_ami_id                       = local.base_ami_id_ue1
  external_role                        = module.application_iam_roles.obproxy_iam_role_name
  external_instance_profile            = module.outboundproxy_uw2.proxy_instance_profile
  slack_events_sns_hook_arn            = var.slack_alarms_sns_hook_arn_use1
  name                                 = var.name
  region                               = "us-east-1"
  fisma_tag                            = var.fisma_tag
  instance_type_outboundproxy          = var.instance_type_outboundproxy
  proxy_enabled_roles                  = var.proxy_enabled_roles
  route53_internal_zone_id             = module.internal_dns_use1[count.index].internal_zone_id
  hostname                             = "obproxy.login.gov.internal"
  use_spot_instances                   = var.use_spot_instances
  vpc_id                               = module.network_use1[0].vpc_id
  proxy_subnet_ids                     = [for subnet in module.network_use1[0].app_subnet : subnet.id]
  base_security_group_id               = module.network_use1[0].base_id
  proxy_security_group_id              = module.network_use1[0].security_group_id
  proxy_for                            = ""
  ssm_access_policy                    = module.ssm_ue1[count.index].ssm_access_role_policy
  s3_secrets_bucket_name               = local.secrets_bucket_ue1
  autoscaling_time_zone                = var.autoscaling_time_zone
  autoscaling_schedule_name            = var.autoscaling_schedule_name
  use_outboundproxy_rotation_schedules = true

  depends_on = [
    module.network_use1
  ]
}
