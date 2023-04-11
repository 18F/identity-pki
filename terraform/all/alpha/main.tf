provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["917793222841"] # require login-alpha
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

variable "splunk_oncall_endpoint" {
  default = "UNSET"
}

module "main" {
  source = "../module"

  opsgenie_key_ready     = false
  splunk_oncall_endpoint = var.splunk_oncall_endpoint
  iam_account_alias      = "login-alpha"
  #dnssec_zone_exists = true
}
