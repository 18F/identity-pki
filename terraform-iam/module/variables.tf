# attach rds_delete_prevent and region_restriction to all roles
locals {
  custom_policy_arns = [
    aws_iam_policy.rds_delete_prevent.arn,
    aws_iam_policy.region_restriction.arn,
  ]
  master_assumerole_policy = data.aws_iam_policy_document.master_account_assumerole.json
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

variable "iam_appdev_enabled" {
  description = "Enable appdev role in this account."
  type        = bool
  default     = true
}

variable "dashboard_logos_bucket_write" {
  description = "Permit AppDev role write access to static logos buckets"
  type        = bool
  default     = false
}

variable "iam_power_enabled" {
  description = "Enable power role in this account."
  type        = bool
  default     = true
}

variable "iam_readonly_enabled" {
  description = "Enable readonly role in this account."
  type        = bool
  default     = true
}

variable "iam_socadmin_enabled" {
  description = "Enable socadmin role in this account."
  type        = bool
  default     = true
}

variable "iam_billing_enabled" {
  description = "Enable billing role in this account."
  type        = bool
  default     = true
}

variable "iam_reports_enabled" {
  description = "Enable reports role in this account."
  type        = bool
  default     = false
}

variable "reports_bucket_arn" {
  description = "ARN for the S3 bucket for reports."
  type        = string
  default     = ""
}
