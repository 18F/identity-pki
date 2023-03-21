provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["217680906704"] # require login-tooling-prod
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  bootstrap_main_git_ref_default  = "stages/gitlabproduction"
  dr_region                       = "us-east-2"
  env_name                        = "production"
  env_type                        = "tooling-prod"
  region                          = "us-west-2"
  slack_events_sns_hook_arn       = "arn:aws:sns:us-west-2:217680906704:slack-events"
  root_domain                     = "gitlab.login.gov"
  default_ami_id_tooling          = "ami-06cf1d7554298d746" # 2023-03-21 Ubuntu 18.04
  route53_id                      = "Z07730471OKZ5T4V8NB2M"
  asg_gitlab_test_runner_desired  = 38
  asg_gitlab_build_runner_desired = 4
  destination_artifact_accounts   = ["894947205914"] # login-sandbox
  destination_idp_static_accounts = ["894947205914"] # login-sandbox
  production                      = true
  accountids                      = ["894947205914", "034795980528", "217680906704"]
  asg_outboundproxy_desired       = 2
  asg_outboundproxy_min           = 2
  use_waf_rules                   = true
  gitlab_runner_enabled           = true
  env_runner_gitlab_hostname      = "gitlab.gitstaging.gitlab.login.gov"
  env_runner_config_bucket        = "login-gov-gitstaging-gitlabconfig-217680906704-us-west-2"
  gitlab_servicename              = "com.amazonaws.vpce.us-west-2.vpce-svc-07880c3ca1e0f631f"
  newrelic_pager_alerts_enabled   = 1
  rds_engine_version              = "13.7"
  cloudwatch_treat_missing_data   = "missing"
}

output "gitlab_db_host" {
  value = module.main.gitlab_db_host
}
