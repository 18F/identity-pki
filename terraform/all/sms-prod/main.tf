provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["472911866628"] # require login-prod
  profile             = "sms.login.gov"
  version             = "~> 2.67.0"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  iam_account_alias  = "login-sms-prod"
  account_roles_map = {
    iam_appdev_enabled = false
  }
}
