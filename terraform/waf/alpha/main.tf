provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["034795980528"] # require login-prod
  profile             = "login-tooling-sandbox"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source            = "../module"
  env               = "alpha"
  region            = "us-west-2"
  enforce           = true
  waf_alert_actions = ["arn:aws:sns:us-west-2:034795980528:slack-otherevents"]
  lb_name           = "alpha-gitlab-waf"
  ship_logs_to_soc  = false
}
