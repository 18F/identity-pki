provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["340731855345"] # require login-master
  profile             = "login-master"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  iam_account_alias = "login-master"
  account_roles_map = {
    iam_appdev_enabled    = false
    iam_power_enabled     = false
    iam_readonly_enabled  = false
    iam_socadmin_enabled  = true
    iam_terraform_enabled = false
    iam_billing_enabled   = true
  }
}
