locals {
  region     = "us-west-2"
  account_id = "894947205914"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id] # require login-sandbox
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source                 = "../module"
  account_name           = "sandbox"
  slack_notification_arn = "arn:aws:sns:${local.region}:${local.account_id}:slack-otherevents"
}