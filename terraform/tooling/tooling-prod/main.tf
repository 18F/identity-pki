locals {
  region     = "us-west-2"
  account_id = "217680906704"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id] # require login-tooling-prod
}

# Stub remote config
terraform {
  backend "s3" {
  }
}
