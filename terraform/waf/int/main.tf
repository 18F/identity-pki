provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["894947205914"] # require login-sms-sandbox
  profile             = "identitysandbox.gov"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  env           = "crissupb"
  region        = "us-west-2"
  waf_override  = "count"
  associate_alb = false
}