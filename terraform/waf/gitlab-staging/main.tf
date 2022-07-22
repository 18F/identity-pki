provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["217680906704"] # require login-tooling-prod
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "waf_data" {
  source   = "../../modules/waf_data_gitlab"
  vpc_name = "login-vpc-gitstaging"
}

module "main" {
  source            = "../module"
  env               = "gitstaging"
  region            = "us-west-2"
  enforce           = true
  waf_alert_actions = ["arn:aws:sns:us-west-2:217680906704:slack-otherevents"]
  lb_name           = "gitstaging-gitlab-waf"
  ship_logs_to_soc  = false
  restricted_paths  = module.waf_data.gitlab_restricted_paths
  privileged_ips    = module.waf_data.gitlab_privileged_ips
  geo_allow_list    = module.waf_data.us_regions
}
