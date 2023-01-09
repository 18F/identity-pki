provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["035466892286"] # require login-sandbox
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"
}
