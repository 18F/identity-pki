provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["221972985980"] # require login-archive-sandbox
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"
}
