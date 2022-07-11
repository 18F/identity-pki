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
