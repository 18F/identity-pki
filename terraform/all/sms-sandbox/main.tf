provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["035466892286"] # require login-sandbox
  profile             = "sms.identitysandbox.gov"
  version             = "~> 2.37.0"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  iam_account_alias  = "login-sms-sandbox"
  account_roles_map = {
    iam_appdev_enabled = false
  }
}
