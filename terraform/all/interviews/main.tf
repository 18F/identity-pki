provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["034795980528"] # require login-interviews
  profile             = "login-interviews"
  version             = "~> 2.37.0"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source                       = "../module"

  iam_account_alias  = "login-interviews"
  account_roles_map = {
    iam_appdev_enabled = false
  }
}
