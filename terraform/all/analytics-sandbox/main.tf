locals {
  region     = "us-west-2"
  account_id = "487317109730"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id] # require login-analytics-sandbox
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source            = "../module"
  iam_account_alias = "login-analytics-sandbox"

  account_purpose = "data_warehouse"

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

  account_slack_channels = {
    "data-warehouse-events"      = "login-data-warehouse-events"
    "data-warehouse-otherevents" = "login-data-warehouse-otherevents"
  }

  ssm_document_access_map = {
    "FullAdministrator" = [{ "*" = ["*"] }],
    "PowerUser"         = [{ "*" = ["*"] }],
    "Terraform"         = [{ "*" = ["*"] }],
    #"FraudOps"          = [],     # must fill in if uncommenting
  }

  ssm_command_access_map = {
    "FullAdministrator" = [{ "*" = ["*"] }],
    "PowerUser"         = [{ "*" = ["*"] }],
    "Terraform"         = [{ "*" = ["*"] }],
    #"FraudOps"          = [],     # must fill in if uncommenting
  }

}

