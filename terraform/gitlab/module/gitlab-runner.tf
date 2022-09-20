# A pool that can build images and push them to ECR
module "build_pool" {
  source = "../../modules/gitlab_runner_pool/"

  allow_untagged_jobs              = false
  asg_gitlab_runner_desired        = var.asg_gitlab_build_runner_desired
  asg_outboundproxy_desired        = var.asg_outboundproxy_desired
  asg_outboundproxy_max            = var.asg_outboundproxy_max
  asg_outboundproxy_min            = var.asg_outboundproxy_min
  aws_vpc                          = aws_vpc.default.id
  base_security_group_id           = aws_security_group.base.id
  bootstrap_main_git_ref_default   = var.bootstrap_main_git_ref_default
  bootstrap_main_git_ref_map       = var.bootstrap_main_git_ref_map
  bootstrap_main_s3_ssh_key_url    = local.bootstrap_main_s3_ssh_key_url
  bootstrap_private_s3_ssh_key_url = local.bootstrap_private_s3_ssh_key_url
  default_ami_id_tooling           = var.default_ami_id_tooling
  destination_artifact_accounts    = var.destination_artifact_accounts
  destination_idp_static_accounts  = var.destination_idp_static_accounts
  enable_ecr_write                 = true
  env_name                         = var.env_name
  github_ipv4_cidr_blocks          = local.github_ipv4_cidr_blocks
  gitlab_lb_interface_cidr_blocks  = local.gitlab_lb_interface_cidr_blocks
  gitlab_runner_pool_name          = "build-pool"
  proxy_server                     = "obproxy-build-pool.login.gov.internal"
  root_domain                      = var.root_domain
  route53_id                       = var.route53_id
  route53_internal_zone_id         = aws_route53_zone.internal.zone_id
  runner_subnet_ids                = [for zone in local.network_zones : aws_subnet.apps[zone].id]
  s3_prefix_list_id                = aws_vpc_endpoint.private-s3.prefix_list_id
  slack_events_sns_hook_arn        = var.slack_events_sns_hook_arn
  endpoint_security_groups         = local.default_endpoint_security_group_ids
  ssm_access_policy                = module.ssm.ssm_access_role_policy
  runner_gitlab_hostname           = "gitlab.${var.env_name}.${var.root_domain}"
  gitlab_configbucket              = local.runner_config_bucket
  vpc_cidr_block                   = aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
}

# A pool for testing infrastructure
module "test_pool" {
  source = "../../modules/gitlab_runner_pool/"

  allow_untagged_jobs              = true
  asg_gitlab_runner_desired        = var.asg_gitlab_test_runner_desired
  asg_outboundproxy_desired        = var.asg_outboundproxy_desired
  asg_outboundproxy_max            = var.asg_outboundproxy_max
  asg_outboundproxy_min            = var.asg_outboundproxy_min
  aws_vpc                          = aws_vpc.default.id
  base_security_group_id           = aws_security_group.base.id
  bootstrap_main_git_ref_default   = var.bootstrap_main_git_ref_default
  bootstrap_main_git_ref_map       = var.bootstrap_main_git_ref_map
  bootstrap_main_s3_ssh_key_url    = local.bootstrap_main_s3_ssh_key_url
  bootstrap_private_s3_ssh_key_url = local.bootstrap_private_s3_ssh_key_url
  default_ami_id_tooling           = var.default_ami_id_tooling
  enable_ecr_write                 = false
  env_name                         = var.env_name
  github_ipv4_cidr_blocks          = local.github_ipv4_cidr_blocks
  gitlab_lb_interface_cidr_blocks  = local.gitlab_lb_interface_cidr_blocks
  gitlab_runner_pool_name          = "test-pool"
  proxy_server                     = "obproxy-test-pool.login.gov.internal"
  root_domain                      = var.root_domain
  route53_id                       = var.route53_id
  route53_internal_zone_id         = aws_route53_zone.internal.zone_id
  runner_subnet_ids                = [for zone in local.network_zones : aws_subnet.apps[zone].id]
  s3_prefix_list_id                = aws_vpc_endpoint.private-s3.prefix_list_id
  slack_events_sns_hook_arn        = var.slack_events_sns_hook_arn
  endpoint_security_groups         = local.default_endpoint_security_group_ids
  ssm_access_policy                = module.ssm.ssm_access_role_policy
  runner_gitlab_hostname           = "gitlab.${var.env_name}.${var.root_domain}"
  gitlab_configbucket              = local.runner_config_bucket
  vpc_cidr_block                   = aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
}

# A runner that can deploy stuff to this environment
module "env-runner" {
  count  = var.gitlab_runner_enabled ? 1 : 0
  source = "../../modules/gitlab_runner_pool/"

  allow_untagged_jobs              = false
  asg_gitlab_runner_desired        = 1
  asg_outboundproxy_desired        = var.asg_outboundproxy_desired
  asg_outboundproxy_max            = var.asg_outboundproxy_max
  asg_outboundproxy_min            = var.asg_outboundproxy_min
  aws_vpc                          = aws_vpc.default.id
  base_security_group_id           = aws_security_group.base.id
  bootstrap_main_git_ref_default   = var.bootstrap_main_git_ref_default
  bootstrap_main_git_ref_map       = var.bootstrap_main_git_ref_map
  bootstrap_main_s3_ssh_key_url    = local.bootstrap_main_s3_ssh_key_url
  bootstrap_private_s3_ssh_key_url = local.bootstrap_private_s3_ssh_key_url
  default_ami_id_tooling           = local.account_default_ami_id
  env_name                         = var.env_name
  github_ipv4_cidr_blocks          = local.github_ipv4_cidr_blocks
  gitlab_lb_interface_cidr_blocks  = local.gitlab_lb_interface_cidr_blocks
  gitlab_runner_pool_name          = "env-runner"
  proxy_server                     = "obproxy-env-runner.login.gov.internal"
  root_domain                      = var.root_domain
  route53_id                       = var.route53_id
  route53_internal_zone_id         = aws_route53_zone.internal.zone_id
  runner_subnet_ids                = [for zone in local.network_zones : aws_subnet.apps[zone].id]
  s3_prefix_list_id                = aws_vpc_endpoint.private-s3.prefix_list_id
  slack_events_sns_hook_arn        = var.slack_events_sns_hook_arn
  endpoint_security_groups         = local.default_endpoint_security_group_ids
  ssm_access_policy                = module.ssm.ssm_access_role_policy
  terraform_powers                 = true
  is_it_an_env_runner              = true
  gitlab_ecr_repo_accountid        = data.aws_caller_identity.current.account_id
  runner_gitlab_hostname           = local.env_runner_gitlab_hostname
  gitlab_configbucket              = local.env_runner_config_bucket
  vpc_cidr_block                   = aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
}

# This enables the gitlab privatelink endpoint in the VPC for
# the env_runner
module "gitlab" {
  count      = var.gitlab_runner_enabled ? 1 : 0
  depends_on = [aws_internet_gateway.default]
  source     = "../../modules/gitlab"

  gitlab_servicename      = var.gitlab_servicename
  endpoint_subnet_ids     = slice([for zone in local.network_zones : aws_subnet.endpoints[zone].id], 0, 2)
  vpc_id                  = aws_vpc.default.id
  env_name                = var.env_name
  allowed_security_groups = [aws_security_group.base.id]
  route53_zone_id         = aws_route53_zone.internal.zone_id
  dns_name                = local.env_runner_gitlab_hostname
}
