provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["555546682965"] # require login-prod
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "waf_data" {
  source   = "../../modules/waf_data_idp"
  vpc_name = "login-vpc-prod"
}

module "main" {
  source = "../module"

  env     = "prod"
  region  = "us-west-2"
  enforce = true

  # Uncomment to use header_block_regex filter
  #header_block_regex = yamldecode(file("header_block_regex.yml"))

  # commenting this out to free up one of our 10(!) available
  # per-account per-region regex pattern sets
  #query_block_regex  = ["ExampleStringToBlock"]

  waf_alert_blocked_threshold = "1500"
  waf_alert_actions           = ["arn:aws:sns:us-west-2:555546682965:slack-events"]

  restricted_paths    = module.waf_data.restricted_paths
  privileged_cidrs_v4 = module.waf_data.privileged_cidrs_v4
  privileged_cidrs_v6 = module.waf_data.privileged_cidrs_v6
}

module "cloudfront-waf" {
  source = "../module"

  wafv2_web_acl_scope = "CLOUDFRONT"
  env                 = "prod"
  region              = "us-east-1"
  enforce             = true
  soc_destination_arn = "arn:aws:logs:us-east-1:752281881774:destination:elp-waf-lg"

  # Uncomment to use header_block_regex filter
  #header_block_regex = yamldecode(file("header_block_regex.yml"))

  waf_alert_blocked_threshold = "5000"
  waf_alert_actions           = ["arn:aws:sns:us-east-1:555546682965:slack-events"]
}
