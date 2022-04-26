provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["034795980528"] # require login-tooling-sandbox
  profile             = "login-tooling-sandbox"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  bootstrap_main_git_ref_default = "stages/gitlabbravo"
  env_name                       = "bravo"
  region                         = "us-west-2"
  slack_events_sns_hook_arn      = "arn:aws:sns:us-west-2:034795980528:slack-otherevents"
  default_ami_id_tooling         = "ami-04eb44f13c683a210" # 2022-04-20 base-20220420070421 Ubuntu 18.04
  route53_id                     = "Z096400532ZFM348WWIAA"
  production                     = true
  # These are the account IDs who can access this cluster's gitlab service.
  accountids = ["894947205914", "034795980528", "217680906704"]
}
