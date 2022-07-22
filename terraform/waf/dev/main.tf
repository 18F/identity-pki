provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["894947205914"] # require login-sandbox
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

  header_block_regex = yamldecode(file("header_block_regex.yml"))

  # commenting this out to free up one of our 10(!) available
  # per-account per-region regex pattern sets
  #query_block_regex  = ["ExampleStringToBlock"]

  waf_alert_actions = ["arn:aws:sns:us-west-2:894947205914:slack-otherevents"]
}
