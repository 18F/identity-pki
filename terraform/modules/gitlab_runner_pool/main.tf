data "aws_caller_identity" "current" {
}

module "outbound_proxy" {
  source = "../outbound_proxy"

  account_default_ami_id           = var.default_ami_id_tooling
  ami_id_map                       = var.ami_id_map
  base_security_group_id           = var.base_security_group_id
  bootstrap_main_git_ref_default   = local.bootstrap_main_git_ref_default
  bootstrap_private_git_ref        = local.bootstrap_private_git_ref
  bootstrap_private_s3_ssh_key_url = var.bootstrap_private_s3_ssh_key_url
  client_security_group_ids        = [aws_security_group.gitlab_runner.id]
  env_name                         = var.env_name
  github_ipv4_cidr_blocks          = var.github_ipv4_cidr_blocks
  hostname                         = "obproxy-${var.gitlab_runner_pool_name}.login.gov.internal"
  proxy_for                        = var.gitlab_runner_pool_name
  proxy_subnet_ids                 = var.runner_subnet_ids
  root_domain                      = var.root_domain
  route53_internal_zone_id         = var.route53_internal_zone_id
  s3_secrets_bucket_name           = var.s3_secrets_bucket_name
  s3_prefix_list_id                = var.s3_prefix_list_id
  slack_events_sns_hook_arn        = var.slack_events_sns_hook_arn
  vpc_id                           = var.aws_vpc
  asg_outboundproxy_desired        = var.asg_outboundproxy_desired
  asg_outboundproxy_max            = var.asg_outboundproxy_max
  asg_outboundproxy_min            = var.asg_outboundproxy_min
  ssm_access_policy                = var.ssm_access_policy
  vpc_cidr_block                   = var.vpc_cidr_block
  cloudwatch_treat_missing_data    = var.cloudwatch_treat_missing_data
}
