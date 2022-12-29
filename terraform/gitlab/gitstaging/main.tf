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

  bootstrap_main_git_ref_default  = "stages/gitstaging"
  dr_region                       = "us-east-2"
  env_name                        = "gitstaging"
  env_type                        = "tooling-staging"
  region                          = "us-west-2"
  root_domain                     = "gitlab.login.gov"
  slack_events_sns_hook_arn       = "arn:aws:sns:us-west-2:034795980528:slack-events"
  default_ami_id_tooling          = "ami-03e9b66d5f0ab9c78" # 2022-12-27 Ubuntu 18.04
  route53_id                      = "Z07730471OKZ5T4V8NB2M"
  asg_gitlab_test_runner_desired  = 2
  asg_gitlab_build_runner_desired = 2
  destination_artifact_accounts   = ["894947205914"] # login-sandbox
  destination_idp_static_accounts = ["894947205914"] # login-sandbox
  production                      = false
  accountids                      = ["894947205914", "034795980528", "217680906704"]
  asg_outboundproxy_desired       = 1
  asg_outboundproxy_min           = 1
  use_waf_rules                   = true
  gitlab_runner_enabled           = true
  env_runner_gitlab_hostname      = "gitlab.login.gov"
  env_runner_config_bucket        = "login-gov-production-gitlabconfig-217680906704-us-west-2"
  gitlab_servicename              = "com.amazonaws.vpce.us-west-2.vpce-svc-0270024908d73003b"
}

output "gitlab_db_host" {
  value = module.main.gitlab_db_host
}
