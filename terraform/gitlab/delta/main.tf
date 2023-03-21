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
  env_type                       = "tooling-sandbox"
  gitlab_az                      = "us-east-2a"
  region                         = "us-east-2"
  dr_region                      = "us-west-2"
  slack_events_sns_hook_arn      = "arn:aws:sns:us-east-2:034795980528:slack-otherevents"
  route53_id                     = "Z096400532ZFM348WWIAA"
  accountids                     = ["894947205914", "034795980528", "217680906704"]
  no_proxy_hosts                 = "localhost,127.0.0.1,169.254.169.254,169.254.169.123,.login.gov.internal,.us-east-2.amazonaws.com"
  rds_engine_version             = "13.7"
}

output "env_name" {
  value = module.main.env_name
}

output "region" {
  value = module.main.region
}

output "latest_available_ami_id" {
  value = module.main.latest_available_ami_id
}

output "default_ami_id" {
  value = module.main.default_ami_id
}

output "ami_id_map" {
  value = module.main.ami_id_map
}