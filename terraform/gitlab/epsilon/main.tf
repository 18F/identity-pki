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

variable "rds_password" {
  default = ""
}

module "main" {
  source = "../module"

  rds_password                   = var.rds_password
  bootstrap_main_git_ref_default = "stages/gitlabepsilon"
  env_name                       = "epsilon"
  region                         = "us-west-2"
  dr_region                      = "us-east-2"
  slack_events_sns_hook_arn      = "arn:aws:sns:us-west-2:034795980528:slack-otherevents"
  default_ami_id_tooling         = "ami-0b6395c0bb69bef0e" # 2022-05-11 base-20220518070421 Ubuntu 18.04
  route53_id                     = "Z096400532ZFM348WWIAA"
  accountids                     = ["894947205914", "034795980528", "217680906704"]
}
