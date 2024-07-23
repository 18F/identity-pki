locals {
  region     = "us-west-2"
  account_id = "894947205914"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id] # require login-sandbox
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  env                   = "int"
  region                = "us-west-2"
  enforce               = true
  enforce_waf_captcha   = false
  enforce_waf_challenge = false
  enforce_rate_limit    = true
  geo_allow_list        = [] # allow all countries in app WAFv2

  anonymous_ip_ruleset_actions = {
    "AnonymousIPList"       = "count",
    "HostingProviderIPList" = "block"
  }

  waf_alert_actions  = ["arn:aws:sns:us-west-2:894947205914:slack-otherevents"]
  ddos_alert_actions = ["arn:aws:sns:us-west-2:894947205914:slack-otherevents"]

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
  automated_ddos_protection_action = "Block"
}

module "cloudfront-waf" {
  source = "../module"

  wafv2_web_acl_scope              = "CLOUDFRONT"
  env                              = "int"
  region                           = "us-east-1"
  enforce                          = true
  soc_destination_arn              = "arn:aws:logs:us-east-1:752281881774:destination:elp-waf-lg"
  enforce_rate_limit               = true
  email_password_rate_limit_per_ip = 100
  geo_allow_list                   = [] # allow all countries in app WAFv2

  anonymous_ip_ruleset_actions = {
    "AnonymousIPList"       = "count",
    "HostingProviderIPList" = "block"
  }

  waf_alert_actions = ["arn:aws:sns:us-east-1:894947205914:slack-otherevents"]
}
