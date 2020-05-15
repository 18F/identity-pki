provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["472911866628"] # require login-sms-prod
  profile             = "sms.login.gov"

  #assume_role {
  #  role_arn     = "arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME"
  #  session_name = "SESSION_NAME"
  #  external_id  = "EXTERNAL_ID"
  #}

  version = "~> 2.29"
}

# Stub remote config
terraform {
  backend "s3" {
  }

  # allowed terraform version
  required_version = "~> 0.12"
}

module "account_pinpoint" {
  # These are provisoned per-AWS account. This module should only be used
  # in the us-west-2 environment.
  source = "../../modules/account_pinpoint/"

  main_account_id = "555546682965"
}

module "main" {
  source = "../module"

  env                           = "prod"
  region                        = "us-west-2"
  pinpoint_app_name             = "login.gov"
  state_lock_table              = "terraform_locks"
  opsgenie_devops_high_endpoint = "https://api.opsgenie.com/v1/json/amazonsns?apiKey=1b1a2d80-6260-460a-995a-5200876f7372"
  sns_topic_arn_slack_events    = "arn:aws:sns:us-west-2:472911866628:slack-login-events"
  pinpoint_spend_limit          = 100000 # USD monthly
}

output "pinpoint_app_id" {
  value = module.main.pinpoint_app_id
}

output "pinpoint_idp_role_arn" {
  value = module.account_pinpoint.pinpoint_idp_role_arn
}

