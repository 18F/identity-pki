provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["555546682965"] # require login-prod
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  env     = "prod"
  region  = "us-west-2"
  enforce = true

  waf_alert_actions           = ["arn:aws:sns:us-west-2:555546682965:slack-events"]
  waf_alert_blocked_threshold = "1500"
}

module "cloudfront-waf" {
  source = "../module"

  wafv2_web_acl_scope         = "CLOUDFRONT"
  env                         = "prod"
  region                      = "us-east-1"
  enforce                     = true
  soc_destination_arn         = "arn:aws:logs:us-east-1:752281881774:destination:elp-waf-lg"
  waf_alert_blocked_threshold = "1500"
  waf_alert_actions           = ["arn:aws:sns:us-west-2:555546682965:slack-events"]
}
