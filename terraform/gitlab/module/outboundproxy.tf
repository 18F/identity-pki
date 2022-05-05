module "outbound_proxy" {
  source = "../../modules/outbound_proxy"

  account_default_ami_id           = var.default_ami_id_tooling
  ami_id_map                       = var.ami_id_map
  base_security_group_id           = aws_security_group.base.id
  bootstrap_main_git_ref_default   = local.bootstrap_main_git_ref_default
  bootstrap_main_s3_ssh_key_url    = local.bootstrap_main_s3_ssh_key_url
  bootstrap_private_s3_ssh_key_url = local.bootstrap_private_s3_ssh_key_url
  env_name                         = var.env_name
  proxy_subnet_ids                 = [aws_subnet.privatesubnet1.id, aws_subnet.privatesubnet2.id, aws_subnet.privatesubnet3.id]
  route53_internal_zone_id         = aws_route53_zone.internal.zone_id
  s3_prefix_list_id                = aws_vpc_endpoint.private-s3.prefix_list_id
  slack_events_sns_hook_arn        = var.slack_events_sns_hook_arn
  vpc_id                           = aws_vpc.default.id
  github_ipv4_cidr_blocks          = local.github_ipv4_cidr_blocks
  root_domain                      = var.root_domain
  proxy_for                        = "gitlab"
  client_security_group_ids        = [aws_security_group.gitlab.id]
}
