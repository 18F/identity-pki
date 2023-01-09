provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["340731855345"] # require login-master
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"
}
