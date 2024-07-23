locals {
  region     = "us-west-2"
  account_id = "034795980528"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id] # require login-tooling-sandbox
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

#module "waf_data" {
#  source   = "../../modules/waf_data_gitlab"
#  vpc_name = "login-vpc-bravo"
#}

module "main" {
  source            = "../module"
  env               = "bravo"
  app               = "gitlab"
  region            = "us-west-2"
  enforce           = true
  waf_alert_actions = ["arn:aws:sns:us-west-2:034795980528:slack-otherevents"]
  lb_name           = "bravo-gitlab-waf"
  ship_logs_to_soc  = false
}
