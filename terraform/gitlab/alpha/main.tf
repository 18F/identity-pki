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

  env_name                  = "alpha"
  region                    = "us-west-2"
  slack_events_sns_hook_arn = "arn:aws:sns:us-west-2:034795980528:slack-events"
  #enforce                  = true
}
