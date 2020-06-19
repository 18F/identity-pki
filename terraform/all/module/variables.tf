# attach rds_delete_prevent and region_restriction to all roles
locals {
  custom_policy_arns = [
    aws_iam_policy.rds_delete_prevent.arn,
    aws_iam_policy.region_restriction.arn,
  ]
  
  master_assumerole_policy = data.aws_iam_policy_document.master_account_assumerole.json
  
  role_enabled_defaults = {
    iam_appdev_enabled    = true
    iam_analytics_enabled = false
    iam_power_enabled     = true
    iam_readonly_enabled  = true
    iam_socadmin_enabled  = true
    iam_terraform_enabled = true
    iam_billing_enabled   = true
    iam_reports_enabled   = false
    iam_kmsadmin_enabled  = false
  }
}

variable "iam_account_alias" {
  description = "Account alias in AWS."
}

variable "region" {
  default = "us-west-2"
}

variable "state_lock_table" {
  description = "Name of the DynamoDB table to use for state locking with the S3 state backend, e.g. 'terraform-locks'"
  default     = "terraform_locks"
}

variable "manage_state_bucket" {
  description = <<EOM
Whether to manage the TF remote state bucket and lock table.
Set this to false if you want to skip this for bootstrapping.
EOM
  type        = bool
  default     = true
}

variable "master_account_id" {
  default     = "340731855345"
  description = "AWS Account ID for master account"
}

variable "auditor_accounts" {
  description = "Map of non-Login.gov AWS accounts we allow Security Auditor access to"
  # Unlike our master account, these are accounts we do not control!
  type = map(string)
  default = {
    master        = "340731855345" # Include master for testing
    techportfolio = "133032889584" # TTS Tech Portfolio
  }
}

variable "dashboard_logos_bucket_write" {
  description = "Permit AppDev role write access to static logos buckets"
  type        = bool
  default     = false
}

variable "reports_bucket_arn" {
  description = "ARN for the S3 bucket for reports."
  type        = string
  default     = ""
}

variable "account_roles_map" {
  description = "Map of roles that are enabled/disabled in current account."
  type        = map
}