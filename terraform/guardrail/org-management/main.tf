provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["121998818467"] # require login-org-management
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"
}
