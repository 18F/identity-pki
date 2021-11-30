provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["034795980528"] # require login-tooling
  profile             = "login-tooling"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  bootstrap_main_git_ref_default = "stages/gitlabecho"
  env_name                       = "echo"
  region                         = "us-west-2"
  slack_events_sns_hook_arn      = "arn:aws:sns:us-west-2:034795980528:slack-otherevents"
  #enforce                  = true
}

output "gitaly_volume_id" {
  value = module.main.gitaly_volume_id
}

output "gitlab_redis_endpoint" {
  value = module.main.gitlab_redis_endpoint
}
