provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["035466892286"] # require login-sms-sandbox
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "account_pinpoint" {
  # These are provisoned per-AWS account. This module should only be used
  # in the us-west-2 environment.
  source = "../../modules/account_pinpoint/"

  main_account_id = "894947205914"
}

module "main" {
  source = "../module"

  env                      = "sandbox"
  region                   = "us-west-2"
  pinpoint_app_name        = "identitysandbox.gov"
  state_lock_table         = "terraform_locks"
  sns_topic_alert_critical = "slack-events"
  sns_topic_alert_warning  = "slack-events"
  pinpoint_spend_limit     = 100000 # USD monthly
  sms_support_api_endpoint = "https://idp.int.identitysandbox.gov/api/country-support.json"

  # Set lower alarm threshold and only exclude US from SMS alarms
  sms_unexpected_country_alarm_default_threshold = 20
  ignored_countries                              = "US"
}

output "pinpoint_app_id" {
  value = module.main.pinpoint_app_id
}

output "pinpoint_idp_role_arn" {
  value = module.account_pinpoint.pinpoint_idp_role_arn
}
