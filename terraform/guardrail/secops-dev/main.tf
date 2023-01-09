provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["138431511372"] # require login-secops-dev
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"
}
