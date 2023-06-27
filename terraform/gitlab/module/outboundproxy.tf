module "outbound_proxy_net" {
  source = "../../modules/outbound_proxy_net"

  env_name                = var.env_name
  github_ipv4_cidr_blocks = local.github_ipv4_cidr_blocks
  vpc_id                  = aws_vpc.default.id
  s3_prefix_list_id       = aws_vpc_endpoint.private-s3.prefix_list_id
  vpc_cidr_block          = aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
}

module "outbound_proxy" {
  source = "../../modules/outbound_proxy"

  default_ami_id                   = local.default_base_ami_id
  ami_id_map                       = var.ami_id_map
  base_security_group_id           = aws_security_group.base.id
  proxy_security_group_id          = module.outbound_proxy_net.security_group_id
  bootstrap_main_git_ref_default   = local.bootstrap_main_git_ref_default
  bootstrap_private_git_ref        = local.bootstrap_private_git_ref
  bootstrap_main_s3_ssh_key_url    = local.bootstrap_main_s3_ssh_key_url
  bootstrap_private_s3_ssh_key_url = local.bootstrap_private_s3_ssh_key_url
  env_name                         = var.env_name
  proxy_subnet_ids                 = [for zone in local.network_zones : aws_subnet.apps[zone].id]
  route53_internal_zone_id         = aws_route53_zone.internal.zone_id
  s3_secrets_bucket_name           = data.aws_s3_bucket.secrets.bucket
  slack_events_sns_hook_arn        = var.slack_events_sns_hook_arn
  root_domain                      = var.root_domain
  proxy_for                        = "gitlab"
  vpc_id                           = aws_vpc.default.id
  ssm_access_policy                = module.ssm.ssm_access_role_policy
  asg_outboundproxy_desired        = var.asg_outboundproxy_desired
  asg_outboundproxy_max            = var.asg_outboundproxy_max
  asg_outboundproxy_min            = var.asg_outboundproxy_min
  cloudwatch_treat_missing_data    = var.cloudwatch_treat_missing_data
}

moved {
  from = module.outbound_proxy.aws_security_group.obproxy
  to   = module.outbound_proxy_net.aws_security_group.obproxy
}