provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["121998818467"] # require login-org-management
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  opsgenie_key_ready = false
  iam_account_alias  = "login-org-management"
  account_roles_map = {
    iam_analytics_enabled      = true
    iam_power_enabled          = false
    iam_readonly_enabled       = false
    iam_socadmin_enabled       = false
    iam_terraform_enabled      = false
    iam_auto_terraform_enabled = false
    iam_billing_enabled        = true
    iam_reports_enabled        = false
    iam_kmsadmin_enabled       = false
    iam_supporteng_enabled     = false
  }

  # Temporary till SOCaaS is ready to accept logs
  soc_logs_enabled = false
}
