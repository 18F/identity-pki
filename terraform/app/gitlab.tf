# This enables the gitlab privatelink endpoint in the VPC so that
# we can get to gitlab from the environments that have these turned on
# in your identity-devops-private/vars/env.tfvars:
#   gitlab_servicename    = "<endpoint name>"
#   gitlab_hostname       = "gitlab.<whatever>.gov"
#   gitlab_enabled        = true
#
module "gitlab" {
  count      = var.gitlab_enabled ? 1 : 0
  depends_on = [module.network_uw2]
  source     = "../modules/gitlab"

  gitlab_servicename = var.gitlab_servicename
  # not supported in us-west-2d
  endpoint_subnet_ids     = slice([for subnet in module.network_uw2.app_subnet : subnet.id], 0, 2)
  vpc_id                  = module.network_uw2.vpc_id
  name                    = var.name
  env_name                = var.env_name
  allowed_security_groups = [module.network_uw2.base_id]
  route53_zone_id         = module.internal_dns_uw2.internal_zone_id
  dns_name                = var.gitlab_hostname
}

# A runner that can deploy stuff to this environment
# To get this going, you will need to have these things turned on in your
# identity-devops-private/vars/env.tfvars, as well as the `gitlab_enabled`
# stuff as documented above:
#   gitlab_runner_enabled = true
#   gitlab_configbucket   = "login-gov-<env>-gitlabconfig-<env accountid>-<region>"
#
# You will also need to set up these in the identity-devops/kitchen/environments/env.json
# file:
#   "gitlab_url": "gitlab.<whatever>.gov",
#   "gitlab_config_s3_bucket": "login-gov-<env>-gitlabconfig-<accountid>-<region>"
#
module "env-runner" {
  count  = var.gitlab_runner_enabled ? 1 : 0
  source = "../modules/gitlab_runner_pool/"

  allow_untagged_jobs              = false
  asg_gitlab_runner_desired        = 1
  asg_outboundproxy_desired        = 1
  asg_outboundproxy_max            = 2
  asg_outboundproxy_min            = 1
  aws_vpc                          = module.network_uw2.vpc_id
  base_security_group_id           = module.network_uw2.base_id
  bootstrap_main_git_ref_default   = local.bootstrap_main_git_ref_default
  bootstrap_private_git_ref        = local.bootstrap_private_git_ref
  bootstrap_main_git_ref_map       = var.bootstrap_main_git_ref_map
  bootstrap_main_s3_ssh_key_url    = local.bootstrap_main_s3_ssh_key_url
  bootstrap_private_s3_ssh_key_url = local.bootstrap_private_s3_ssh_key_url
  default_ami_id                   = local.account_default_ami_id
  env_name                         = var.env_name
  github_ipv4_cidr_blocks          = local.github_ipv4
  gitlab_lb_interface_cidr_blocks  = [var.gitlab_subnet_cidr_block]
  gitlab_runner_pool_name          = "env-runner"
  instance_type_gitlab_runner      = var.instance_type_env_runner
  proxy_server                     = "obproxy-env-runner.login.gov.internal"
  root_domain                      = var.root_domain
  route53_id                       = var.route53_id
  route53_internal_zone_id         = module.internal_dns_uw2.internal_zone_id
  runner_subnet_ids                = [for subnet in module.network_uw2.app_subnet : subnet.id]
  s3_prefix_list_id                = module.network_uw2.s3_prefix_list_id
  s3_secrets_bucket_name           = data.aws_s3_bucket.secrets.bucket
  slack_events_sns_hook_arn        = var.slack_alarms_sns_hook_arn

  endpoint_security_groups  = [for k, v in local.aws_endpoints : module.network_uw2.endpoint_sg[k]]
  gitlab_configbucket       = var.gitlab_configbucket
  ssm_access_policy         = module.ssm_uw2.ssm_access_role_policy
  terraform_powers          = true
  is_it_an_env_runner       = true
  gitlab_ecr_repo_accountid = var.gitlab_ecr_repo_accountid
  runner_gitlab_hostname    = var.gitlab_hostname
}
