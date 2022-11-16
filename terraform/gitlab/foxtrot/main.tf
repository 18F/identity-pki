provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["034795980528"] # require login-tooling
  profile             = "login-tooling"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  bootstrap_main_git_ref_default = "abarbara/foxtrotgitlab"
  env_name                       = "foxtrot"
  env_type                       = "tooling-sandbox"
  region                         = "us-west-2"
  slack_events_sns_hook_arn      = "arn:aws:sns:us-west-2:034795980528:slack-otherevents"
  dr_region                      = "us-east-2"
  default_ami_id_tooling         = "ami-03436eeb5f77f43f4" # 2022-11-15 Ubuntu 18.04
  route53_id                     = "Z096400532ZFM348WWIAA"
  destination_artifact_accounts  = ["894947205914"] # login-sandbox
  # These are the account IDs who can access this cluster's gitlab service.
  accountids = ["894947205914", "034795980528", "217680906704"]
}
