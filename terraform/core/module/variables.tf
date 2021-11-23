variable "region" {
  default = "us-west-2"
}

variable "state_lock_table" {
  description = "Name of the DynamoDB table to use for state locking with the S3 state backend, e.g. 'terraform-locks'"
}

variable "manage_state_bucket" {
  description = <<EOM
Whether to manage the TF remote state bucket and lock table.
Set this to false if you want to skip this for bootstrapping.
EOM
  type        = bool
  default     = true
}

variable "root_domain" {
  description = "DNS domain to use as the root domain, e.g. login.gov"
}

variable "dnssec_ksks" {
  description = "Map of Key Signing Keys (KSKs) to provision for each zone"
  # To safely rotate see https://github.com/18F/identity-devops/wiki/Runbook:-DNS#ksk-rotation
  type = map(string)
  default = {
    "20211006" = "green",
    # "YYYYMMDD" = "blue"
  }
}

variable "static_cloudfront_name" {
  description = "Static site Cloudfront DNS name, e.g. abcd.cloudfront.net"
}

variable "design_cloudfront_name" {
  description = "Design site Cloudfront DNS name, e.g. abcd.cloudfront.net"
}

variable "developers_cloudfront_name" {
  description = "Developers site Cloudfront DNS name, e.g. abcd.cloudfront.net"
}

variable "acme_partners_cloudfront_name" {
  description = "Partners site Cloudfront DNS name, e.g. abcd.cloudfront.net"
}

variable "google_site_verification_txt" {
  description = "Google site verification text to put in TXT record"
  default     = ""
}

variable "mx_provider" {
  description = "Name of the MX provider to set up records for, see common_dns module"
}

variable "mta_sts_max_age" {
  description = "Age (TTL) in seconds to cache MTA-STS policy - Must be between 86400 (1 day) and 31557600 (about 1 year)"
  type        = number
  # Default - 1 week
  default = 604800
}

variable "mta_sts_mode" {
  description = "MTA-STS mode - Allowed values: testing, enforce, none"
  type        = string
  default     = "testing"
}

variable "mta_sts_report_mailboxes" {
  description = "List of email addresses to receive MTS-STS TLS reports"
  type        = list(string)
}

variable "sandbox_ses_inbound_enabled" {
  description = "Whether to enable identitysandbox.gov style SES inbound processing"
  default     = 0
}

variable "sandbox_ses_email_users" {
  description = "List of additional users (besides admin) to accept - user@domain will be allowed and delivers to inbox/user/"
  type        = list(string)
  default     = []
}

variable "lambda_identity_lambda_functions_gitrev" {
  default     = "07af04c7bb53fde03ed9a705953b1881490d8c05"
  description = "Initial gitrev of identity-lambda-functions to deploy (updated outside of terraform)"
}

variable "lambda_audit_github_enabled" {
  default     = 1
  description = "Whether to run the audit-github lambda in this account"
}

variable "lambda_audit_github_debug" {
  default     = 1
  description = "Whether to run the audit-github lambda in debug mode in this account"
}

variable "lambda_audit_aws_enabled" {
  default     = 1
  description = "Whether to run the audit-aws lambda in this account"
}

variable "ttl_verification_record" {
  description = "TTL value for the SES verification TXT record."
  type        = string
  default     = "1800"
}

variable "prod_records" {
  description = "Additional Route53 mappings for the prod login.gov account."
  type        = list(any)
  default     = []
}

variable "slack_sns_name" {
  description = "Name for SNS topic for Slack notifications."
  type        = string
}

variable "bucket_list_uw2" {
  description = "List of us-west-2 buckets to add S3 Inventory Management to."
  type        = list(any)
  default     = []
}

variable "bucket_list_ue1" {
  description = "List of us-west-2 buckets to add S3 Inventory Management to."
  type        = list(any)
  default     = []
}

variable "slack_events_sns_hook_arn" {
  description = "Slack sns topic"
  type        = string
}

variable "guardduty_threat_feed_name" {
  description = "Name of the GuardDuty threat feed, used to name other resources"
  type        = string
  default     = "gd-threat-feed"
}

variable "guardduty_days_requested" {
  type    = number
  default = 7
}

variable "guardduty_frequency" {
  type    = number
  default = 6
}

variable "guardduty_threat_feed_code" {
  type        = string
  description = "Path of the compressed lambda source code."
  default     = "src/guard-duty-threat-feed.zip"
}