provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["217680906704"] # require login-tooling-prod
  profile             = "login-tooling-prod"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}
