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

  bootstrap_main_git_ref_default = "stages/gitlabproduction"
  env_name                       = "production"
  region                         = "us-west-2"
  slack_events_sns_hook_arn      = "arn:aws:sns:us-west-2:034795980528:slack-otherevents"
  root_domain                    = "gitlab.login.gov"
  default_ami_id_tooling         = "ami-0046bdebfcb2ee91d"
  route53_id                     = "Z07730471OKZ5T4V8NB2M"
  asg_gitlab_test_runner_desired = 4
}

output "gitlab_db_host" {
  value = module.main.gitlab_db_host
}
