provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["035466892286"] # require identity-sandbox
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

  state_lock_table   = "terraform_locks"
  iam_appdev_enabled = false
}
