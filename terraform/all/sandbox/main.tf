provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["894947205914"] # require login-sandbox
  profile             = "identitysandbox.gov"
  version             = "~> 2.37.0"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  iam_account_alias            = "login-sandbox"
  dashboard_logos_bucket_write = true
  account_roles_map = {
    iam_kmsadmin_enabled         = true
  }
}
