provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["487317109730"] # require login-analytics-sandbox
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
  iam_account_alias = "login-analytics-sandbox"

  splunk_oncall_cloudwatch_endpoint = var.splunk_oncall_cloudwatch_endpoint
  splunk_oncall_newrelic_endpoint   = var.splunk_oncall_newrelic_endpoint

  account_roles_map = {
    iam_analytics_enabled      = true
    iam_auto_terraform_enabled = true
    iam_billing_enabled        = false
    iam_fraudops_enabled       = true
    iam_power_enabled          = true
    iam_readonly_enabled       = false
    iam_reports_enabled        = false # No reports buckets defined yet
    iam_socadmin_enabled       = true
    iam_supporteng_enabled     = true
    iam_terraform_enabled      = true
  }

  ssm_document_access_map = {
    "FullAdministrator" = [{ "*" = ["*"] }],
    "PowerUser"         = [{ "*" = ["*"] }],
    "Terraform"         = [{ "*" = ["*"] }],
    "FraudOps"          = [],
  }

  ssm_command_access_map = {
    "FullAdministrator" = [{ "*" = ["*"] }],
    "PowerUser"         = [{ "*" = ["*"] }],
    "Terraform"         = [{ "*" = ["*"] }],
    "FraudOps"          = [],
  }

}

