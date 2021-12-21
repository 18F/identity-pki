provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["917793222841"] # require login-alpha
  profile             = "login-alpha"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  opsgenie_key_ready = false
  iam_account_alias  = "login-alpha"
  #dnssec_zone_exists = true
  account_roles_map = {
    iam_appdev_enabled = false
  }
}
