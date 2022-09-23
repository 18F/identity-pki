provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["894947205914"] # require login-sandbox
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "waf_data" {
  source   = "../../modules/waf_data_idp"
  vpc_name = "login-vpc-dev"
}

module "main" {
  source = "../module"

  env     = "dev"
  region  = "us-west-2"
  enforce = true

  # commenting this out to free up one of our 10(!) available
  # per-account per-region regex pattern sets
  #header_block_regex = yamldecode(file("header_block_regex.yml"))

  #query_block_regex  = ["ExampleStringToBlock"]

  waf_alert_actions = ["arn:aws:sns:us-west-2:894947205914:slack-otherevents"]

  restricted_paths    = module.waf_data.restricted_paths
  privileged_cidrs_v4 = module.waf_data.privileged_cidrs_v4
  privileged_cidrs_v6 = module.waf_data.privileged_cidrs_v6
}

module "cloudfront-waf" {
  source = "../module"

  wafv2_web_acl_scope = "CLOUDFRONT"
  env                 = "dev"
  region              = "us-east-1"
  enforce             = true
  soc_destination_arn = "arn:aws:logs:us-east-1:752281881774:destination:elp-waf-lg"

  header_block_regex = yamldecode(file("header_block_regex.yml"))

  waf_alert_actions = ["arn:aws:sns:us-east-1:894947205914:slack-otherevents"]
}
