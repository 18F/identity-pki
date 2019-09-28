provider "aws" {
  region = "us-west-2"
  allowed_account_ids = ["035466892286"] # require identity-sms-sandbox
  profile = "sms.identitysandbox.gov"

  #assume_role {
  #  role_arn     = "arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME"
  #  session_name = "SESSION_NAME"
  #  external_id  = "EXTERNAL_ID"
  #}

  version = "~> 2.29"
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

  #env = "sandbox"
  region = "us-west-2"
  main_account_id = "894947205914"
  pinpoint_app_name = "identitysandbox.gov"
  state_lock_table = "terraform_locks"
  opsgenie_devops_high_endpoint = "https://api.opsgenie.com/v1/json/amazonsns?apiKey=1b1a2d80-6260-460a-995a-5200876f7372"
}
