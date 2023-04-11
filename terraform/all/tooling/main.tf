provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["034795980528"] # require login-tooling-sandbox
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

variable "opsgenie_key_ready" {
  default = true
}

variable "splunk_oncall_endpoint" {
  default = "UNSET"
}

module "main" {
  source = "../module"

  dnssec_zone_exists     = true
  slack_events_sns_topic = "slack-events"
  opsgenie_key_ready     = var.opsgenie_key_ready
  splunk_oncall_endpoint = var.splunk_oncall_endpoint
  iam_account_alias      = "login-tooling-sandbox"
  smtp_user_ready        = true

  ssm_access_map = {
    "FullAdministrator" = [{ "*" = ["*"] }],
    "PowerUser"         = [{ "*" = ["*"] }],
    "Terraform"         = [{ "*" = ["*"] }],
  }
}
