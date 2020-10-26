provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["555546682965"] # require login-prod
  profile             = "login.gov"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  env           = "staging"
  region        = "us-west-2"
  enforce       = false
  associate_alb = false
}


