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
  vpc_name = "login-vpc-int"
}

module "main" {
  source = "../module"

  env     = "int"
  region  = "us-west-2"
  enforce = true

  # Uncomment to use header_block_regex filter
  #header_block_regex = yamldecode(file("header_block_regex.yml"))

  # commenting this out to free up one of our 10(!) available
  # per-account per-region regex pattern sets
  #query_block_regex  = ["ExampleStringToBlock"]

  waf_alert_actions = ["arn:aws:sns:us-west-2:894947205914:slack-otherevents"]

  restricted_paths    = module.waf_data.restricted_paths
  privileged_cidrs_v4 = module.waf_data.privileged_cidrs_v4
  privileged_cidrs_v6 = module.waf_data.privileged_cidrs_v6
  aws_shield_resources = {
    cloudfront = [
      "arn:aws:cloudfront::894947205914:distribution/E1A8CHVMW6MJUO",
      "arn:aws:cloudfront::894947205914:distribution/EGE6BD9ZWJEDK"
    ],
    route53_hosted_zone = [
      "arn:aws:route53:::hostedzone/ZZ8OBT9NXH5K1",
      "arn:aws:route53:::hostedzone/Z2XX1V1EBJTJ8K",
      "arn:aws:route53:::hostedzone/ZEYKSG9SJ951W"
    ],
    global_accelerator = [],
    application_loadbalancer = [
      "arn:aws:elasticloadbalancing:us-west-2:894947205914:loadbalancer/app/login-app-alb-int/f7824828070c6523",
      "arn:aws:elasticloadbalancing:us-west-2:894947205914:loadbalancer/app/login-idp-alb-int/dc500788936e9dd0"
    ],
    classic_loadbalancer = [
      "arn:aws:elasticloadbalancing:us-west-2:894947205914:loadbalancer/int-pivcac"
    ],
    elastic_ip_address = []
  }
}

module "cloudfront-waf" {
  source = "../module"

  wafv2_web_acl_scope = "CLOUDFRONT"
  env                 = "int"
  region              = "us-east-1"
  enforce             = true
  soc_destination_arn = "arn:aws:logs:us-east-1:752281881774:destination:elp-waf-lg"

  # Uncomment to use header_block_regex filter
  #header_block_regex = yamldecode(file("header_block_regex.yml"))

  waf_alert_actions = ["arn:aws:sns:us-east-1:894947205914:slack-otherevents"]
}