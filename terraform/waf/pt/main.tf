provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["894947205914"] # require login-sandbox
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  env            = "pt"
  region         = "us-west-2"
  enforce        = false
  geo_allow_list = [] # allow all countries in app WAFv2

  waf_alert_actions  = ["arn:aws:sns:us-west-2:894947205914:slack-otherevents"]
  ddos_alert_actions = ["arn:aws:sns:us-west-2:894947205914:slack-otherevents"]
}

module "cloudfront-waf" {
  source = "../module"

  wafv2_web_acl_scope = "CLOUDFRONT"
  env                 = "pt"
  region              = "us-east-1"
  enforce             = false
  soc_destination_arn = "arn:aws:logs:us-east-1:752281881774:destination:elp-waf-lg"

  # populate to define rules to COUNT (and BLOCK all others),
  # or leave blank to skip applying the bot control ruleset
  bot_control_exclusions = []

  waf_alert_actions = ["arn:aws:sns:us-east-1:894947205914:slack-otherevents"]
}
