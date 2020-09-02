variable "region" {
  default = "us-west-2"
}

variable "state_lock_table" {
  description = "Name of the DynamoDB table to use for state locking with the S3 state backend, e.g. 'terraform-locks'"
}

variable "allow_public_buckets" {
  description = "Permit account to host public buckets"
  type        = bool
  default     = true # At the time this was added, prod allowed public s3 buckets, sandbox did not
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

variable "root_domain" {
  description = "DNS domain to use as the root domain, e.g. login.gov"
}

variable "static_cloudfront_name" {
  description = "Static site Cloudfront DNS name, e.g. abcd.cloudfront.net"
  default     = "todo.cloudfront.net"
}

variable "design_cloudfront_name" {
  description = "Design site Cloudfront DNS name, e.g. abcd.cloudfront.net"
  default     = "todo.cloudfront.net"
}

variable "developers_cloudfront_name" {
  description = "Developers site Cloudfront DNS name, e.g. abcd.cloudfront.net"
  default     = "todo.cloudfront.net"
}

variable "acme_partners_cloudfront_name" {
  description = "Partners site Cloudfront DNS name, e.g. abcd.cloudfront.net"
  default     = "todo.cloudfront.net"
}

variable "google_site_verification_txt" {
  description = "Google site verification text to put in TXT record"
  default     = ""
}

variable "mx_provider" {
  description = "Name of the MX provider to set up records for, see common_dns module"
}

variable "sandbox_ses_inbound_enabled" {
  description = "Whether to enable identitysandbox.gov style SES inbound processing"
  default     = 0
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
