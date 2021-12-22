locals {
  common_account_name = var.iam_account_alias == "login-master" ? "global" : replace(var.iam_account_alias, "login-", "")
  dnssec_policy_arn   = var.dnssec_zone_exists ? data.aws_iam_policy.dnssec_disable_prevent[0].arn : ""

  # attach rds_delete_prevent and region_restriction to all roles
  custom_policy_arns = compact([
    aws_iam_policy.rds_delete_prevent.arn,
    aws_iam_policy.region_restriction.arn,
    local.dnssec_policy_arn,
  ])

  master_assumerole_policy = data.aws_iam_policy_document.master_account_assumerole.json

  role_enabled_defaults = {
    iam_appdev_enabled         = true
    iam_analytics_enabled      = false
    iam_power_enabled          = true
    iam_readonly_enabled       = true
    iam_socadmin_enabled       = true
    iam_terraform_enabled      = true
    iam_auto_terraform_enabled = true
    iam_billing_enabled        = true
    iam_reports_enabled        = false
    iam_kmsadmin_enabled       = false
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

variable "tooling_account_id" {
  default     = "034795980528"
  description = "AWS Account ID for tooling account"
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

variable "s3_block_all_public_access" {
  description = "Set to true to disable all S3 public access, account wide"
  type        = bool
  default     = true
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
  type        = map(any)
}

variable "cloudtrail_event_selectors" {
  description = "Map of event_selectors used by default CloudTrail."
  type        = list(any)
  default     = []
}

variable "slack_username" {
  description = "Default username for SNS-to-Slack alert to display in Slack channels."
  type        = string
  default     = "SNSToSlack Notifier"
}

variable "slack_icon" {
  description = "Default icon for SNS-to-Slack alert to display in Slack channels."
  type        = string
  default     = ":login-dot-gov:"
}

variable "legacy_bucket_list" {
  description = <<EOM
List of ad-hoc / legacy S3 buckets created outside of Terraform / unmanaged
by the identity-devops repo, now configured with Intelligent Tiering storage.
EOM
  type        = list(string)
  default     = []
}

variable "opsgenie_key_ready" {
  description = <<EOM
Whether or not the OpsGenie API key is present in this account's secrets
bucket. Defaults to TRUE; set to FALSE only when building from scratch,
as the key will need to be uploaded into the bucket once it has been created.
EOM
  type        = bool
  default     = true
}

variable "tf_slack_channel" {
  description = "Slack channel where Terraform change notifications should be sent."
  type        = string
  default     = "#login-change"
}

variable "smtp_user_ready" {
  description = <<EOM
Whether or not the SMTP user is present in this account, and the SMTP username
and password are in this account's secrets bucket. Defaults to FALSE; set to
TRUE after the user has been created and the secrets have been uploaded to the
bucket.
EOM
  type        = bool
  default     = false
}

variable "config_access_key_rotation_name" {
  description = "Name of the Config access key rotation, used to name other resources"
  type        = string
  default     = "cfg-access-key-rotation"
}

variable "config_access_key_rotation_frequency" {
  type        = string
  description = "The frequency that you want AWS Config to run evaluations for the rule."
  default     = "Six_Hours"
}

variable "config_access_key_rotation_max_key_age" {
  type        = string
  description = "Maximum number of days without rotation. Default 90."
  default     = 90
}

variable "config_access_key_rotation_code" {
  type        = string
  description = "Path of the compressed lambda source code."
  default     = "src/config-access-key-rotation.zip"
}

variable "slack_events_sns_topic" {
  type        = string
  description = "Name of the SNS topic for slack."
  default     = "slack-otherevents"
}

variable "dnssec_zone_exists" {
  type        = bool
  description = <<EOM
Whether or not DNSSEC is enabled for the primary hosted zone. If it does, get
the DNSSecDisablePrevent IAM policy and attach it to all roles.
EOM
  default     = false
}

variable "externalId" {
  type        = string
  description = "sts assume role, externalId for Prisma Cloud role"
  default     = "3b5fe41c-f3f1-4b36-84a5-5d2a665c87c9"
}

variable "accountNumberPrisma" {
  type        = string
  description = "Commericial Prisma AWS account id"
  default     = "188619942792"
}
 