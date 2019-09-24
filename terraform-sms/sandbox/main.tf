provider "aws" {
  region = "us-west-2"
  allowed_account_ids = ["035466892286"] # require identity-sms-sandbox
  profile = "sms.identitysandbox.gov"

  #assume_role {
  #  role_arn     = "arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME"
  #  session_name = "SESSION_NAME"
  #  external_id  = "EXTERNAL_ID"
  #}
}

# Stub remote config
terraform {
  backend "s3" {
  }

  # allowed terraform version
  required_version = "~> 0.11.7"
}

module "main" {
  source = "../module"

  env = "sandbox"
  region = "us-west-2"
  main_account_id = "894947205914"
  pinpoint_app_name = "identitysandbox.gov"
}
