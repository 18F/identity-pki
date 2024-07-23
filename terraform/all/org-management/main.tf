locals {
  region     = "us-west-2"
  account_id = "121998818467"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id] # require login-org-management
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

variable "splunk_oncall_cloudwatch_endpoint" {
  default = "UNSET"
}

module "main" {
  source            = "../module"
  iam_account_alias = "login-org-management"

  splunk_oncall_cloudwatch_endpoint = var.splunk_oncall_cloudwatch_endpoint

  account_roles_map = {
    iam_analytics_enabled      = true
    iam_power_enabled          = false
    iam_readonly_enabled       = false
    iam_socadmin_enabled       = false
    iam_terraform_enabled      = false
    iam_auto_terraform_enabled = false
  }
}
