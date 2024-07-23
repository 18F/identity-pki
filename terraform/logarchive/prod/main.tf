locals {
  region     = "us-west-2"
  account_id = "429506220995"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id] # require login-logarchive-prod
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source            = "../module"
  source_account_id = "555546682965" # login-prod
  #secondary_region = "us-east-1" # disable for now
  log_record_s3_keys = "NO" # don't log S3 object names to CloudWatch
}
