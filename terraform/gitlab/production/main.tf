locals {
  region     = "us-west-2"
  account_id = "217680906704"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id] # require login-tooling-prod
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
  default_ami_id                  = "ami-0631422a89ac1b3e0" # 2024-09-17 Ubuntu 20.04
  route53_id                      = "Z07730471OKZ5T4V8NB2M"
  asg_gitlab_test_runner_desired  = 38
  asg_gitlab_build_runner_desired = 4
  destination_artifact_accounts   = ["894947205914"] # login-sandbox
  destination_idp_static_accounts = ["894947205914"] # login-sandbox
  production                      = true
  accountids                      = ["894947205914", "034795980528", "217680906704", "487317109730"]
  asg_outboundproxy_desired       = 2
  asg_outboundproxy_min           = 2
  use_waf_rules                   = true
  gitlab_runner_enabled           = true
  env_runner_gitlab_hostname      = "gitlab.gitstaging.gitlab.login.gov"
  env_runner_config_bucket        = "login-gov-gitstaging-gitlabconfig-217680906704-us-west-2"
  gitlab_servicename              = "com.amazonaws.vpce.us-west-2.vpce-svc-07880c3ca1e0f631f"
  newrelic_pager_alerts_enabled   = 1
  cloudwatch_treat_missing_data   = "missing"
  send_cw_to_soc                  = 1
  rds_engine_version              = "14.13"
  rds_auto_minor_version_upgrade  = false
  rds_allow_major_version_upgrade = false
}

output "gitlab_db_host" {
  value = module.main.gitlab_db_host
}

output "env_name" {
  value = module.main.env_name
}

output "region" {
  value = module.main.region
}

output "latest_available_ami_id" {
  value = module.main.latest_available_ami_id
}

output "default_ami_id" {
  value = module.main.default_ami_id
}

output "ami_id_map" {
  value = module.main.ami_id_map
}
