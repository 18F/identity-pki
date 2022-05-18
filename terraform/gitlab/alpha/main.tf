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

  bootstrap_main_git_ref_default = "stages/gitlabalpha"
  env_name                       = "alpha"
  region                         = "us-west-2"
  slack_events_sns_hook_arn      = "arn:aws:sns:us-west-2:034795980528:slack-otherevents"
  default_ami_id_tooling         = "ami-08d81eaa9fe849343" # 2022-05-03 base-20220503070419 Ubuntu 18.04
  route53_id                     = "Z096400532ZFM348WWIAA"
  destination_artifact_accounts  = ["894947205914"] # login-sandbox
  accountids                     = ["894947205914", "034795980528", "217680906704"]
  asg_gitlab_test_runner_desired = 4
}
