provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["035466892286"] # require identity-sms-sandbox
  profile             = "sms.identitysandbox.gov"

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

module "global" {
  # These are provisoned per-AWS account. This module should only be used
  # in the us-west-2 environment.
  source = "../global"

  main_account_id = "894947205914"
}

module "main" {
  source = "../module"

  env                           = "sandbox"
  region                        = "us-west-2"
  pinpoint_app_name             = "identitysandbox.gov"
  state_lock_table              = "terraform_locks"
  opsgenie_devops_high_endpoint = "https://api.opsgenie.com/v1/json/amazonsns?apiKey=1b1a2d80-6260-460a-995a-5200876f7372"
  sns_topic_arn_slack_events    = "arn:aws:sns:us-west-2:035466892286:slack-login-otherevents"
  pinpoint_spend_limit          = 100000 # USD monthly
}

output "pinpoint_app_id" {
  value = module.main.pinpoint_app_id
}

output "pinpoint_idp_role_arn" {
  value = module.global.pinpoint_idp_role_arn
}
