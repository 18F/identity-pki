locals {
  region     = "us-west-2"
  account_id = "917793222841"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id] # require login-alpha
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source            = "../module"
  iam_account_alias = "login-alpha"

  #dnssec_zone_exists = true
}
