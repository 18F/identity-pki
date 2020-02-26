provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["472911866628"] # require identity-prod
  profile             = "sms.login.gov"
  version             = "~> 2.37.0"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  iam_appdev_enabled  = false
}
