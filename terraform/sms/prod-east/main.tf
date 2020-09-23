provider "aws" {
  region              = "us-east-1"
  allowed_account_ids = ["472911866628"] # require login-sms-prod
  profile             = "sms.login.gov"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  env                           = "prod"
  region                        = "us-east-1"
  pinpoint_app_name             = "login.gov"
  state_lock_table              = "terraform_locks"
  opsgenie_devops_high_endpoint = "https://api.opsgenie.com/v1/json/amazonsns?apiKey=1b1a2d80-6260-460a-995a-5200876f7372"
  sns_topic_arn_slack_events    = "arn:aws:sns:us-east-1:472911866628:slack-login-events"
  pinpoint_spend_limit          = 100000 # USD monthly
}

output "pinpoint_app_id" {
  value = module.main.pinpoint_app_id
}
