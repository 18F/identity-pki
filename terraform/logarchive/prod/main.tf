provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["429506220995"] # require login-logarchive-prod
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
