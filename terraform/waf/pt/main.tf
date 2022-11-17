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
  vpc_name = "login-vpc-pt"
}

module "main" {
  source = "../module"

  env     = "pt"
  region  = "us-west-2"
  enforce = false

  # Uncomment to use header_block_regex filter
  #header_block_regex = yamldecode(file("header_block_regex.yml"))

  # commenting this out to free up one of our 10(!) available
  # per-account per-region regex pattern sets
  #query_block_regex  = ["ExampleStringToBlock"]

  waf_alert_actions = ["arn:aws:sns:us-west-2:894947205914:slack-otherevents"]

  restricted_paths    = module.waf_data.restricted_paths
  privileged_cidrs_v4 = module.waf_data.privileged_cidrs_v4
  privileged_cidrs_v6 = module.waf_data.privileged_cidrs_v6
  #aws_shield_resources = {
  #  cloudfront = [
  #    "arn:aws:cloudfront::894947205914:distribution/E2SKBNVQFFAX97",
  #    "arn:aws:cloudfront::894947205914:distribution/E1RBXOBOOSRZSZ"
  #  ],
  #  route53_hosted_zone = [
  #    "arn:aws:route53:::hostedzone/Z015248438UH2QL4VVIZ1",
  #    "arn:aws:route53:::hostedzone/Z05043693NU02M8V00BN0",
  #    "arn:aws:route53:::hostedzone/Z0212390SCD6HC8O77DA"
  #  ],
  #  global_accelerator = [],
  #  application_loadbalancer = [
  #    "arn:aws:elasticloadbalancing:us-west-2:894947205914:loadbalancer/app/login-app-alb-pt/7f574ec377f54891",
  #    "arn:aws:elasticloadbalancing:us-west-2:894947205914:loadbalancer/app/login-idp-alb-pt/7c0d8f0c7182e22a"
  #  ],
  #  classic_loadbalancer = [
  #    "arn:aws:elasticloadbalancing:us-west-2:894947205914:loadbalancer/pt-pivcac"
  #  ],
  #  elastic_ip_address = []
  #}
}

module "cloudfront-waf" {
  source = "../module"

  wafv2_web_acl_scope = "CLOUDFRONT"
  env                 = "pt"
  region              = "us-east-1"
  enforce             = false
  soc_destination_arn = "arn:aws:logs:us-east-1:752281881774:destination:elp-waf-lg"

  # Uncomment to use header_block_regex filter
  #header_block_regex = yamldecode(file("header_block_regex.yml"))

  waf_alert_actions = ["arn:aws:sns:us-east-1:894947205914:slack-otherevents"]
}
