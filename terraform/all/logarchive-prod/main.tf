locals {
  region     = "us-west-2"
  account_id = "429506220995"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id] # require login-logarchive-prod
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source            = "../module"
  iam_account_alias = "login-logarchive-prod"

  #limit_allowed_services = true  # uncomment to limit allowed services for all Roles

  cloudwatch_minimum_retention_days_scanning = 3653

  # Restricted access - TODO: Add a role for historical search of data with
  # possible spilled PII
  account_roles_map = {
    iam_analytics_enabled      = false
    iam_auto_terraform_enabled = true
    iam_billing_enabled        = false
    iam_fraudops_enabled       = false
    iam_power_enabled          = false
    iam_readonly_enabled       = false
    iam_reports_enabled        = false
    iam_socadmin_enabled       = false
    iam_supporteng_enabled     = false
    iam_terraform_enabled      = true
  }
}
