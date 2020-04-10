provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["034795980528"] # require identity-sandbox
  profile             = "secops"
  version             = "~> 2.37.0"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  dashboard_logos_bucket_write = true
  source                       = "../module"
}
