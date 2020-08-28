provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["894947205914"] # require identity-sandbox
  profile             = "identitysandbox.gov"
  version             = "~> 2.67.0"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  state_lock_table            = "terraform_locks"
  slack_sns_name              = "slack-sandbox-events" 
  root_domain                 = "identitysandbox.gov"
  mx_provider                 = "amazon-ses-inbound.us-west-2"
  sandbox_ses_inbound_enabled = 1
}

