provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["217680906704"] # require login-secops-prod
  profile             = "login-secops-prod"
  version             = "~> 2.37.0"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source                       = "../module"

  iam_account_alias  = "login-secops-prod"
  account_roles_map = {
    iam_appdev_enabled = false
  }
}
