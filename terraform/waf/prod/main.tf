provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["555546682965"] # require login-prod
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  env                         = "prod"
  region                      = "us-west-2"
  enforce                     = true
  enforce_rate_limit          = true
  waf_alert_blocked_threshold = "1500"
  geo_allow_list              = [] # allow all countries in app WAFv2

  waf_alert_actions  = ["arn:aws:sns:us-west-2:555546682965:slack-events"]
  ddos_alert_actions = ["arn:aws:sns:us-west-2:555546682965:slack-events"]

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

  waf_alert_blocked_threshold = "5000"
  waf_alert_actions           = ["arn:aws:sns:us-east-1:555546682965:slack-events"]
}
