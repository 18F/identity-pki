provider "aws" {
  region              = "us-east-1"
  allowed_account_ids = ["472911866628"] # require login-sms-prod
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  env                      = "prod"
  region                   = "us-east-1"
  pinpoint_app_name        = "login.gov"
  state_lock_table         = "terraform_locks"
  sns_topic_alert_critical = "splunk-oncall-login-platform"
  sns_topic_alert_warning  = "slack-events"
  pinpoint_spend_limit     = 100000 # USD monthly
}

output "pinpoint_app_id" {
  value = module.main.pinpoint_app_id
}
