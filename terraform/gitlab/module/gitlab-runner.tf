module "gitlab_build_runner_pool" {
  source = "../../modules/gitlab_runner_pool/"

  asg_gitlab_desired         = var.asg_gitlab_desired
  asg_gitlab_runner_desired  = var.asg_gitlab_runner_desired
  asg_outboundproxy_desired  = var.asg_outboundproxy_desired
  asg_outboundproxy_max      = var.asg_outboundproxy_max
  asg_outboundproxy_min      = var.asg_outboundproxy_min
  aws_vpc                    = aws_vpc.default.id
  base_security_group_id     = aws_security_group.base.id
  bootstrap_main_git_ref_map = var.bootstrap_main_git_ref_map
  env_name                   = var.env_name
  github_ipv4_cidr_blocks    = var.github_ipv4_cidr_blocks
  gitlab_runner_pool_name    = "build-1"
  gitlab_subnet_1_id         = aws_subnet.gitlab1.id
  gitlab_subnet_2_id         = aws_subnet.gitlab2.id
  slack_events_sns_hook_arn  = var.slack_events_sns_hook_arn
}
