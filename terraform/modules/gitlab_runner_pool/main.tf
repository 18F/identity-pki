data "aws_caller_identity" "current" {
}

module "outbound_proxy" {
  source = "../outbound_proxy"

  account_default_ami_id           = var.default_ami_id_tooling
  ami_id_map                       = var.ami_id_map
  base_security_group_id           = var.base_security_group_id
  bootstrap_main_git_ref_default   = var.bootstrap_main_git_ref_default
  bootstrap_main_s3_ssh_key_url    = var.bootstrap_main_s3_ssh_key_url
  bootstrap_private_s3_ssh_key_url = var.bootstrap_private_s3_ssh_key_url
  env_name                         = var.env_name
  public_subnets = [
    var.aws_subnet_publicsubnet1_id,
    var.aws_subnet_publicsubnet2_id,
    var.aws_subnet_publicsubnet3_id,
  ]
  route53_internal_zone_id  = var.route53_internal_zone_id
  s3_prefix_list_id         = var.s3_prefix_list_id
  slack_events_sns_hook_arn = var.slack_events_sns_hook_arn
  vpc_id                    = var.aws_vpc
  github_ipv4_cidr_blocks   = var.github_ipv4_cidr_blocks
  root_domain               = var.root_domain
  hostname                  = "obproxy-${var.gitlab_runner_pool_name}.login.gov.internal"
}
