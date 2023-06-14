provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["487317109730"] # require login-analytics-sandbox
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"
}
