locals {
  region     = "us-west-2"
  account_id = "217680906704"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id] # require login-tooling-prod
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

#module "waf_data" {
#  source   = "../../modules/waf_data_gitlab"
#  vpc_name = "login-vpc-production"
#}

module "main" {
  source            = "../module"
  env               = "production"
  app               = "gitlab"
  region            = "us-west-2"
  enforce           = true
  waf_alert_actions = ["arn:aws:sns:us-west-2:217680906704:slack-otherevents"]
  lb_name           = "production-gitlab-waf"
  ship_logs_to_soc  = false
}
