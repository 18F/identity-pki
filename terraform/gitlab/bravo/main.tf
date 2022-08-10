provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["034795980528"] # require login-tooling-sandbox
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  bootstrap_main_git_ref_default = "stages/gitlabbravo"
  dr_region                      = "us-east-2"
  env_name                       = "bravo"
  region                         = "us-west-2"
  slack_events_sns_hook_arn      = "arn:aws:sns:us-west-2:034795980528:slack-otherevents"
  default_ami_id_tooling         = "ami-048730c6de6ae6369" # base-20220809165126 2022-08-09
  route53_id                     = "Z096400532ZFM348WWIAA"
  destination_artifact_accounts  = ["894947205914"] # login-sandbox
  production                     = true
  # These are the account IDs who can access this cluster's gitlab service.
  accountids                = ["894947205914", "034795980528", "217680906704"]
  asg_outboundproxy_desired = 2
  asg_outboundproxy_min     = 2
}
