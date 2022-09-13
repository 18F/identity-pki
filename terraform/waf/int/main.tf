provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["894947205914"] # require login-sms-sandbox
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  env     = "int"
  region  = "us-west-2"
  enforce = true

  waf_alert_actions = ["arn:aws:sns:us-west-2:894947205914:slack-otherevents"]
}

module "cloudfront-waf" {
  source = "../module"

  wafv2_web_acl_scope = "CLOUDFRONT"
  env                 = "int"
  region              = "us-east-1"
  soc_destination_arn = "arn:aws:logs:us-east-1:752281881774:destination:elp-waf-lg"
  enforce             = true
  waf_alert_actions   = ["arn:aws:sns:us-east-1:894947205914:slack-otherevents"]
}
