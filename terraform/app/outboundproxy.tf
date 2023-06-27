module "outboundproxy_net_uw2" {
  source = "../modules/outbound_proxy_net"

  use_prefix              = false
  env_name                = var.env_name
  name                    = var.name
  region                  = var.region
  vpc_cidr_block          = aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
  app_cidr_block          = ""
  vpc_id                  = aws_vpc.default.id
  s3_prefix_list_id       = aws_vpc_endpoint.private-s3.prefix_list_id
  fisma_tag               = var.fisma_tag
  nessusserver_ip         = var.nessusserver_ip
  github_ipv4_cidr_blocks = local.github_ipv4
}

module "outboundproxy_uw2" {
  source = "../modules/outbound_proxy"

  use_prefix                       = false
  external_role                    = module.application_iam_roles.obproxy_iam_role_name
  create_cpu_policy                = false
  ami_id_map                       = var.ami_id_map
  asg_outboundproxy_desired        = var.asg_outboundproxy_desired
  asg_outboundproxy_min            = var.asg_outboundproxy_min
  asg_outboundproxy_max            = var.asg_outboundproxy_max
  asg_prevent_auto_terminate       = var.asg_prevent_auto_terminate
  asg_enabled_metrics              = var.asg_enabled_metrics
  bootstrap_main_git_ref_default   = local.bootstrap_main_git_ref_default
  bootstrap_main_git_ref_map       = var.bootstrap_main_git_ref_map
  bootstrap_main_s3_ssh_key_url    = local.bootstrap_main_s3_ssh_key_url
  bootstrap_main_git_clone_url     = var.bootstrap_main_git_clone_url
  bootstrap_private_git_ref        = local.bootstrap_private_git_ref
  bootstrap_private_s3_ssh_key_url = local.bootstrap_private_s3_ssh_key_url
  bootstrap_private_git_clone_url  = var.bootstrap_private_git_clone_url
  chef_download_url                = var.chef_download_url
  chef_download_sha256             = var.chef_download_sha256
  env_name                         = var.env_name
  root_domain                      = var.root_domain
  default_ami_id                   = local.account_default_ami_id
  slack_events_sns_hook_arn        = var.slack_events_sns_hook_arn
  name                             = var.name
  region                           = var.region
  fisma_tag                        = var.fisma_tag
  instance_type_outboundproxy      = var.instance_type_outboundproxy
  proxy_enabled_roles              = var.proxy_enabled_roles
  route53_internal_zone_id         = aws_route53_zone.internal.zone_id
  hostname                         = "obproxy.login.gov.internal"
  use_spot_instances               = var.use_spot_instances
  vpc_id                           = aws_vpc.default.id
  proxy_subnet_ids                 = [for subnet in aws_subnet.app : subnet.id]
  base_security_group_id           = aws_security_group.base.id
  proxy_security_group_id          = module.outboundproxy_net_uw2.security_group_id
  proxy_for                        = ""
  ssm_access_policy                = module.ssm.ssm_access_role_policy
  s3_secrets_bucket_name           = data.aws_s3_bucket.secrets.bucket
  autoscaling_time_zone            = var.autoscaling_time_zone
  autoscaling_schedule_name        = var.autoscaling_schedule_name
  outboundproxy_rotation_schedules = local.outboundproxy_rotation_schedules

  depends_on = [
    aws_security_group.base,
    module.outboundproxy_net_uw2.security_group_id
  ]
}

##### moved blocks, remove once state moves are complete


moved {
  from = aws_security_group.obproxy
  to   = module.outboundproxy_net_uw2.aws_security_group.obproxy
}

moved {
  from = aws_autoscaling_group.outboundproxy
  to   = module.outboundproxy_uw2.aws_autoscaling_group.outboundproxy
}

moved {
  from = aws_iam_instance_profile.obproxy
  to   = module.outboundproxy_uw2.aws_iam_instance_profile.obproxy
}

moved {
  from = aws_lb.obproxy
  to   = module.outboundproxy_uw2.aws_lb.obproxy
}

moved {
  from = aws_cloudwatch_log_group.squid_access_log
  to   = module.outboundproxy_uw2.aws_cloudwatch_log_group.squid_access_log
}

moved {
  from = aws_lb_listener.obproxy
  to   = module.outboundproxy_uw2.aws_lb_listener.obproxy
}

moved {
  from = aws_lb_target_group.obproxy
  to   = module.outboundproxy_uw2.aws_lb_target_group.obproxy
}

moved {
  from = aws_route53_record.obproxy
  to   = module.outboundproxy_uw2.aws_route53_record.obproxy
}

moved {
  from = module.obproxy_lifecycle_hooks
  to   = module.outboundproxy_uw2.module.obproxy_lifecycle_hooks
}

moved {
  from = module.outboundproxy_cloudwatch_filters
  to   = module.outboundproxy_uw2.module.outboundproxy_cloudwatch_filters
}

moved {
  from = module.outboundproxy_launch_template
  to   = module.outboundproxy_uw2.module.outboundproxy_launch_template
}

moved {
  from = module.outboundproxy_recycle
  to   = module.outboundproxy_uw2.module.outboundproxy_recycle[0]
}

moved {
  from = module.outboundproxy_user_data.aws_s3_object.base_yaml
  to   = module.outboundproxy_uw2.module.outboundproxy_user_data.aws_s3_object.base_yaml
}

moved {
  from = module.outboundproxy_user_data.aws_s3_object.provision_sh
  to   = module.outboundproxy_uw2.module.outboundproxy_user_data.aws_s3_object.provision_sh
}

