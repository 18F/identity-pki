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

  bootstrap_main_git_ref_default = "stages/gitlabcharlie"
  env_name                       = "charlie"
  region                         = "us-west-2"
  slack_events_sns_hook_arn      = "arn:aws:sns:us-west-2:034795980528:slack-otherevents"
  #enforce                       = true
  github_ipv4_cidr_blocks = local.github_ipv4_cidr_blocks
}

output "gitaly_volume_id" {
  value = module.main.gitaly_volume_id
}

output "gitlab_redis_endpoint" {
  value = module.main.gitlab_redis_endpoint
}

locals {
  #  example github data -> https://api.github.com/meta
  ip_regex                = "^[0-9./]*$"
  github_ipv4_cidr_blocks = sort(compact(tolist([for ip in data.github_ip_ranges.git_ipv4.git[*] : ip if length(regexall(local.ip_regex, ip)) > 0])))
}

data "github_ip_ranges" "git_ipv4" {
}
