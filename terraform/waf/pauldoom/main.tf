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

  env                      = "pauldoom"
  region                   = "us-west-2"
  enforce                  = true
  enforce_waf_captcha      = false
  enforce_waf_challenge    = true
  restricted_paths_enforce = false # Count only in Dev
  geo_allow_list           = []    # allow all countries in app WAFv2

  waf_alert_actions = ["arn:aws:sns:us-west-2:894947205914:slack-otherevents"]
}


