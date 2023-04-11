provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["121998818467"] # require login-org-management
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

  opsgenie_key_ready     = var.opsgenie_key_ready
  splunk_oncall_endpoint = var.splunk_oncall_endpoint
  iam_account_alias      = "login-org-management"
  account_roles_map = {
    iam_analytics_enabled      = true
    iam_power_enabled          = false
    iam_readonly_enabled       = false
    iam_socadmin_enabled       = false
    iam_terraform_enabled      = false
    iam_auto_terraform_enabled = false
  }

  # Temporary till SOCaaS is ready to accept logs
  soc_logs_enabled = false
}
