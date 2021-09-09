provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["894947205914"] # require login-sandbox
  profile             = "identitysandbox.gov"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  env     = "dev"
  region  = "us-west-2"
  enforce = true

  waf_alert_actions = ["arn:aws:sns:us-west-2:894947205914:slack-otherevents"]
}
