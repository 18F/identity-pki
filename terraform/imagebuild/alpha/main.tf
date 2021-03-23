provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["917793222841"] # require login-tooling
  profile             = "login-alpha"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  trigger_source = "CloudWatch"
}
