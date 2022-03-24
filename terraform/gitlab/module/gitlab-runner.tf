# A pool that can build images and push them to ECR
module "build_pool" {
  source = "../../modules/gitlab_runner_pool/"

  allow_untagged_jobs              = false
  asg_gitlab_desired               = var.asg_gitlab_desired
  asg_gitlab_runner_desired        = var.asg_gitlab_build_runner_desired
  asg_outboundproxy_desired        = var.asg_outboundproxy_desired
  asg_outboundproxy_max            = var.asg_outboundproxy_max
  asg_outboundproxy_min            = var.asg_outboundproxy_min
  aws_subnet_publicsubnet1_id      = aws_subnet.publicsubnet1.id
  aws_subnet_publicsubnet2_id      = aws_subnet.publicsubnet2.id
  aws_subnet_publicsubnet3_id      = aws_subnet.publicsubnet3.id
  aws_vpc                          = aws_vpc.default.id
  base_security_group_id           = aws_security_group.base.id
  bootstrap_main_git_ref_default   = var.bootstrap_main_git_ref_default
  bootstrap_main_git_ref_map       = var.bootstrap_main_git_ref_map
  bootstrap_main_s3_ssh_key_url    = local.bootstrap_main_s3_ssh_key_url
  bootstrap_private_s3_ssh_key_url = local.bootstrap_private_s3_ssh_key_url
  enable_ecr_write                 = true
  env_name                         = var.env_name
  github_ipv4_cidr_blocks          = local.github_ipv4_cidr_blocks
  gitlab_runner_pool_name          = "build-pool"
  gitlab_subnet_1_id               = aws_subnet.gitlab1.id
  gitlab_subnet_2_id               = aws_subnet.gitlab2.id
  proxy_server                     = "obproxy-build-pool.login.gov.internal"
  root_domain                      = var.root_domain
  route53_internal_zone_id         = aws_route53_zone.internal.zone_id
  s3_prefix_list_id                = aws_vpc_endpoint.private-s3.prefix_list_id
  slack_events_sns_hook_arn        = var.slack_events_sns_hook_arn
  default_ami_id_tooling           = var.default_ami_id_tooling
  route53_id                       = var.route53_id
  destination_artifact_accounts    = var.destination_artifact_accounts
}

# A pool with minimal permissions
module "test_pool" {
  source = "../../modules/gitlab_runner_pool/"

  allow_untagged_jobs              = true
  asg_gitlab_desired               = var.asg_gitlab_desired
  asg_gitlab_runner_desired        = var.asg_gitlab_test_runner_desired
  asg_outboundproxy_desired        = var.asg_outboundproxy_desired
  asg_outboundproxy_max            = var.asg_outboundproxy_max
  asg_outboundproxy_min            = var.asg_outboundproxy_min
  aws_subnet_publicsubnet1_id      = aws_subnet.publicsubnet1.id
  aws_subnet_publicsubnet2_id      = aws_subnet.publicsubnet2.id
  aws_subnet_publicsubnet3_id      = aws_subnet.publicsubnet3.id
  aws_vpc                          = aws_vpc.default.id
  base_security_group_id           = aws_security_group.base.id
  bootstrap_main_git_ref_default   = var.bootstrap_main_git_ref_default
  bootstrap_main_git_ref_map       = var.bootstrap_main_git_ref_map
  bootstrap_main_s3_ssh_key_url    = local.bootstrap_main_s3_ssh_key_url
  bootstrap_private_s3_ssh_key_url = local.bootstrap_private_s3_ssh_key_url
  enable_ecr_write                 = false
  env_name                         = var.env_name
  github_ipv4_cidr_blocks          = local.github_ipv4_cidr_blocks
  gitlab_runner_pool_name          = "test-pool"
  gitlab_subnet_1_id               = aws_subnet.gitlab1.id
  gitlab_subnet_2_id               = aws_subnet.gitlab2.id
  proxy_server                     = "obproxy-test-pool.login.gov.internal"
  root_domain                      = var.root_domain
  route53_internal_zone_id         = aws_route53_zone.internal.zone_id
  s3_prefix_list_id                = aws_vpc_endpoint.private-s3.prefix_list_id
  slack_events_sns_hook_arn        = var.slack_events_sns_hook_arn
  default_ami_id_tooling           = var.default_ami_id_tooling
  route53_id                       = var.route53_id
}
