provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["034795980528"] # require login-tooling-sandbox
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "waf_data" {
  source   = "../../modules/waf_data_gitlab"
  vpc_name = "login-vpc-alpha"
}

module "main" {
  source              = "../module"
  env                 = "alpha"
  app                 = "gitlab"
  region              = "us-west-2"
  enforce             = true
  waf_alert_actions   = ["arn:aws:sns:us-west-2:034795980528:slack-otherevents"]
  lb_name             = "alpha-gitlab-waf"
  ship_logs_to_soc    = false
  restricted_paths    = module.waf_data.restricted_paths
  privileged_cidrs_v4 = module.waf_data.privileged_cidrs_v4
  geo_allow_list      = module.waf_data.us_regions
}