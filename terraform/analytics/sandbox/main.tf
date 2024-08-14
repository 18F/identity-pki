locals {
  region     = "us-west-2"
  account_id = "487317109730"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id] # require login-analytics-sandbox
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

data "aws_caller_identity" "current" {}

module "analytics" {
  source = "../module"

  root_domain = "analytics.identitysandbox.gov"
}
