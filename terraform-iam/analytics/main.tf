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

  state_lock_table         = "terraform_locks"
  iam_billing_enabled      = true
}
