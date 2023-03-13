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

  enforce_rate_limit = true

  # Uncomment to use header_block_regex filter
  #header_block_regex = yamldecode(file("header_block_regex.yml"))

  # commenting this out to free up one of our 10(!) available
  # per-account per-region regex pattern sets
  #query_block_regex  = ["ExampleStringToBlock"]

  waf_alert_blocked_threshold = "1500"
  waf_alert_actions           = ["arn:aws:sns:us-west-2:555546682965:slack-events"]
  ddos_alert_actions          = ["arn:aws:sns:us-west-2:555546682965:slack-events"]

  restricted_paths    = module.waf_data.restricted_paths
  privileged_cidrs_v4 = module.waf_data.privileged_cidrs_v4
  privileged_cidrs_v6 = module.waf_data.privileged_cidrs_v6
  aws_shield_resources = {
    cloudfront = [
      "arn:aws:cloudfront::555546682965:distribution/E1Q088VJTC9NF9", # Cloudfront distro for secure.login.gov
      "arn:aws:cloudfront::555546682965:distribution/EOAW4G8EKUH8W"   # Cloudfront distro for public-reporting-data.prod.login.gov
    ],
    route53_hosted_zone = [
      "arn:aws:route53:::hostedzone/Z32KM8TXXW3ATV", # Hosted zone 16.172.in-addr.arpa
      "arn:aws:route53:::hostedzone/Z1UGLNCRYSFIP4", # Hosted zone pivcac.prod.login.gov
      "arn:aws:route53:::hostedzone/Z3SVVCHC17PLF9"  # Hosted zone login.gov.internal
    ],
    global_accelerator = [],
    application_loadbalancer = [
      "arn:aws:elasticloadbalancing:us-west-2:555546682965:loadbalancer/app/login-idp-alb-prod/46125f90e3d396ab"
    ],
    classic_loadbalancer = [
      "arn:aws:elasticloadbalancing:us-west-2:555546682965:loadbalancer/prod-pivcac"
    ],
    elastic_ip_address = []
  }
  automated_ddos_protection_action = "Count"
}

module "cloudfront-waf" {
  source = "../module"

  wafv2_web_acl_scope = "CLOUDFRONT"
  env                 = "prod"
  region              = "us-east-1"
  enforce             = true
  soc_destination_arn = "arn:aws:logs:us-east-1:752281881774:destination:elp-waf-lg"
  enforce_rate_limit  = true

  # populate to define rules to COUNT (and BLOCK all others),
  # or leave blank to skip applying the bot control ruleset
  bot_control_exclusions = []

  # Uncomment to use header_block_regex filter
  #header_block_regex = yamldecode(file("header_block_regex.yml"))

  waf_alert_blocked_threshold = "5000"
  waf_alert_actions           = ["arn:aws:sns:us-east-1:555546682965:slack-events"]
}
