provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["894947205914"] # require identity-sandbox
  profile             = "identitysandbox.gov"
  version             = "~> 2.37.0"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  state_lock_table            = "terraform_locks"
  slack_events_sns_hook_arn   = "arn:aws:sns:us-west-2:894947205914:identity-events"
  root_domain                 = "identitysandbox.gov"
  mx_provider                 = "amazon-ses-inbound.us-west-2"
  sandbox_ses_inbound_enabled = 1
}
