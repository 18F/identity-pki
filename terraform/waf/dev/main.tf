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

  restricted_paths         = module.waf_data.restricted_paths
  restricted_paths_enforce = false # Count only in Dev
  privileged_cidrs_v4      = module.waf_data.privileged_cidrs_v4
  privileged_cidrs_v6      = module.waf_data.privileged_cidrs_v6
  #aws_shield_resources = {
  #  cloudfront = [
  #    "arn:aws:cloudfront::894947205914:distribution/E1EDIR644EHI8U",
  #    "arn:aws:cloudfront::894947205914:distribution/E3DSTW6UA4IEY5"
  #  ],
  #  route53_hosted_zone = [
  #    "arn:aws:route53:::hostedzone/Z15I3X2AR4NPKG",
  #    "arn:aws:route53:::hostedzone/Z1N1UBANZ5HR30",
  #    "arn:aws:route53:::hostedzone/Z1FPUCEXXWTV7I"
  #  ],
  #  global_accelerator = [],
  #  application_loadbalancer = [
  #    "arn:aws:elasticloadbalancing:us-west-2:894947205914:loadbalancer/app/login-app-alb-dev/14d198f616b82bf9",
  #    "arn:aws:elasticloadbalancing:us-west-2:894947205914:loadbalancer/app/login-idp-alb-dev/c0dbe3a210290854"
  #  ],
  #  classic_loadbalancer = [
  #    "arn:aws:elasticloadbalancing:us-west-2:894947205914:loadbalancer/dev-pivcac"
  #  ],
  #  elastic_ip_address = []
  #}
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
