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
  vpc_name = "login-vpc-staging"
}

module "main" {
  source = "../module"

  env     = "staging"
  region  = "us-west-2"
  enforce = true

  enforce_rate_limit = true

  # Uncomment to use header_block_regex filter
  #header_block_regex = yamldecode(file("header_block_regex.yml"))

  # commenting this out to free up one of our 10(!) available
  # per-account per-region regex pattern sets
  #query_block_regex  = ["ExampleStringToBlock"]

  waf_alert_actions = ["arn:aws:sns:us-west-2:555546682965:slack-otherevents"]

  restricted_paths    = module.waf_data.restricted_paths
  privileged_cidrs_v4 = module.waf_data.privileged_cidrs_v4
  privileged_cidrs_v6 = module.waf_data.privileged_cidrs_v6
  aws_shield_resources = {
    cloudfront = [
      "arn:aws:cloudfront::555546682965:distribution/E219U62GJ2GXKD",
      "arn:aws:cloudfront::555546682965:distribution/E1VUTCRIBG0SX2"
    ],
    route53_hosted_zone = [
      "arn:aws:route53:::hostedzone/Z3E7AW4JDQM95M",
      "arn:aws:route53:::hostedzone/Z1ZBRRO92N8G72",
      "arn:aws:route53:::hostedzone/Z29P7LNIL2XATE"
    ],
    global_accelerator = [],
    application_loadbalancer = [
      "arn:aws:elasticloadbalancing:us-west-2:555546682965:loadbalancer/app/login-idp-alb-staging/bc839ef22f4ef769"
    ],
    classic_loadbalancer = [
      "arn:aws:elasticloadbalancing:us-west-2:555546682965:loadbalancer/staging-pivcac"
    ],
    elastic_ip_address = []
  }
  automated_ddos_protection_action = "Count"
}

module "cloudfront-waf" {
  source = "../module"

  wafv2_web_acl_scope = "CLOUDFRONT"
  env                 = "staging"
  region              = "us-east-1"
  enforce             = true
  soc_destination_arn = "arn:aws:logs:us-east-1:752281881774:destination:elp-waf-lg"
  enforce_rate_limit  = true

  # populate to define rules to COUNT (and BLOCK all others),
  # or leave blank to skip applying the bot control ruleset
  bot_control_exclusions = []

  # Uncomment to use header_block_regex filter
  #header_block_regex = yamldecode(file("header_block_regex.yml"))

  waf_alert_actions = ["arn:aws:sns:us-east-1:555546682965:slack-otherevents"]
}
