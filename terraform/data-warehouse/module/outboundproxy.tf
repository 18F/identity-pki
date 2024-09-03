module "outbound_proxy_net" {
  source = "../../modules/outbound_proxy_net"

  env_name                = var.env_name
  github_ipv4_cidr_blocks = local.github_ipv4_cidr_blocks
  vpc_id                  = aws_vpc.analytics_vpc.id
  s3_prefix_list_id       = aws_vpc_endpoint.private-s3.prefix_list_id
  vpc_cidr_block          = var.vpc_cidr_block
  app_cidr_block          = aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
}

module "outbound_proxy" {
  source = "../../modules/outbound_proxy"

  chef_role                            = "analytics-outboundproxy"
  ami_id_map                           = var.ami_id_map
  external_role                        = "${var.env_name}_obproxy_iam_role"
  asg_outboundproxy_desired            = var.asg_outboundproxy_desired
  asg_outboundproxy_max                = var.asg_outboundproxy_max
  asg_outboundproxy_min                = var.asg_outboundproxy_min
  asg_prevent_auto_terminate           = var.asg_prevent_auto_terminate
  asg_enabled_metrics                  = var.asg_enabled_metrics
  autoscaling_time_zone                = var.autoscaling_time_zone
  autoscaling_schedule_name            = var.autoscaling_schedule_name
  base_security_group_id               = aws_security_group.base.id
  bootstrap_main_git_ref_default       = local.bootstrap_main_git_ref_default
  bootstrap_private_git_ref            = local.bootstrap_private_git_ref
  bootstrap_main_s3_ssh_key_url        = local.bootstrap_main_s3_ssh_key_url
  bootstrap_private_s3_ssh_key_url     = local.bootstrap_private_s3_ssh_key_url
  cloudwatch_treat_missing_data        = var.cloudwatch_treat_missing_data
  default_ami_id                       = var.base_ami_analytics_sandbox_uw2
  env_name                             = var.env_name
  fisma_tag                            = var.fisma_tag
  hostname                             = "obproxy.login.gov.internal"
  instance_type_outboundproxy          = var.instance_type_outboundproxy
  name                                 = var.name
  use_outboundproxy_rotation_schedules = true
  proxy_for                            = "analytics"
  proxy_security_group_id              = module.outbound_proxy_net.security_group_id
  proxy_subnet_ids                     = [for zone in local.network_zones : aws_subnet.apps[zone].id]
  region                               = var.region
  root_domain                          = var.root_domain
  route53_internal_zone_id             = aws_route53_zone.internal.zone_id
  s3_secrets_bucket_name               = data.aws_s3_bucket.secrets.bucket
  slack_events_sns_hook_arn            = var.slack_events_sns_hook_arn
  ssm_access_policy                    = module.ssm.ssm_access_role_policy
  use_prefix                           = false
  use_spot_instances                   = var.use_spot_instances
  vpc_id                               = aws_vpc.analytics_vpc.id
}
