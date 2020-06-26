provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["461353137281"] # require analytics
  profile             = "analytics"
  version             = "~> 2.37.0"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  iam_account_alias = "login-analytics"
  account_roles_map = {
    iam_appdev_enabled    = false
    iam_analytics_enabled = true
    iam_power_enabled     = false
    iam_socadmin_enabled  = true
    iam_terraform_enabled = false
    iam_kmsadmin_enabled  = true
  }
}
