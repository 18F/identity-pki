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

  # allowed terraform version
  required_version = "~> 0.12"
}

module "main" {
  source = "../module"

  state_lock_table    = "terraform_locks"
  iam_appdev_enabled  = false
  iam_billing_enabled = true
  iam_reports_enabled = true
}
