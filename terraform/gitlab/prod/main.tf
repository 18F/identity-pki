provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["217680906704"] # require login-tooling-prod
  profile             = "login-tooling-prod"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  bootstrap_main_git_ref_default = "main"
  env_name                       = "prod"
  region                         = "us-west-2"
  slack_events_sns_hook_arn      = "arn:aws:sns:us-west-2:034795980528:slack-otherevents"
  #enforce                  = true
  root_domain = "gitlab.login.gov"
}

output "gitaly_volume_id" {
  value = module.main.gitaly_volume_id
}

output "gitlab_redis_endpoint" {
  value = module.main.gitlab_redis_endpoint
}

output "gitlab_volume_id" {
  value = module.main.gitlab_volume_id
}
