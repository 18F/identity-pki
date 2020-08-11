provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["555546682965"] # require login-prod
  profile             = "login.gov"
  version             = "~> 2.67.0"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  iam_account_alias    = "login-prod"
  reports_bucket_arn   = "arn:aws:s3:::login-gov.reports.555546682965-us-west-2"
  account_roles_map = {
    iam_reports_enabled   = true
    iam_kmsadmin_enabled  = true
    iam_analytics_enabled = true
  }
}
