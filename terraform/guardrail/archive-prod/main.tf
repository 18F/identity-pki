provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["429506220995"] # require login-archive-prod
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"
}
