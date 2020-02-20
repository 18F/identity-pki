provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["555546682965"] # require identity-prod
  profile             = "login.gov"
  version             = "~> 2.37.0"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  state_lock_table    = "terraform_locks"
  iam_billing_enabled = true
  iam_reports_enabled = true
  reports_bucket_arn  = "arn:aws:s3:::login-gov.reports.555546682965-us-west-2"
}
