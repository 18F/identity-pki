provider "aws" {
  region              = "us-east-2"
  allowed_account_ids = ["034795980528"] # require login-tooling-sandbox
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  bootstrap_main_git_ref_default = "stages/gitlabdelta"
  env_name                       = "delta"
  gitlab_az                      = "us-east-2a"
  region                         = "us-east-2"
  dr_region                      = "us-west-2"
  slack_events_sns_hook_arn      = "arn:aws:sns:us-east-2:034795980528:slack-otherevents"
  default_ami_id_tooling         = "ami-025390aa502ac1b0f" # 2022-05-11 base-20220518070421 Ubuntu 18.04
  route53_id                     = "Z096400532ZFM348WWIAA"
  accountids                     = ["894947205914", "034795980528", "217680906704"]
  no_proxy_hosts                 = "localhost,127.0.0.1,169.254.169.254,169.254.169.123,.login.gov.internal,.us-east-2.amazonaws.com"
}