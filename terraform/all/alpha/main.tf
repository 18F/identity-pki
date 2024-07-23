locals {
  region     = "us-west-2"
  account_id = "917793222841"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id] # require login-alpha
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

variable "splunk_oncall_cloudwatch_endpoint" {
  default = "UNSET"
}

variable "splunk_oncall_newrelic_endpoint" {
  default = "UNSET"
}

module "main" {
  source            = "../module"
  iam_account_alias = "login-alpha"

  splunk_oncall_cloudwatch_endpoint = var.splunk_oncall_cloudwatch_endpoint
  splunk_oncall_newrelic_endpoint   = var.splunk_oncall_newrelic_endpoint

  #dnssec_zone_exists = true
}
