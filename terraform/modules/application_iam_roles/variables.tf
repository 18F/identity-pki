variable "env_name" {
  description = "Environment name, e.g. 'dev', 'staging', 'prod'"
  type        = string
}

variable "escrow_bucket_arn" {
  description = "The ARN of the escrow bucket"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "apps_enabled" {
  description = "A boolean indicating if apps should be created. Use 1 for true and 0 for false."
  type        = number
  default     = 1
}

variable "identity_sms_aws_account_id" {
  description = "Account ID of the AWS account used for Pinpoint and SMS sending (identity-sms-*)"
  type        = string
}

variable "app_secrets_bucket_name_prefix" {
  description = "Base name for the bucket that contains application secrets"
  default     = "login-gov-app-secrets"
}

variable "idp_doc_capture_arn" {
  description = "The ARN of the IDP Doc Capture bucket"
  type        = string
}

variable "idp_doc_capture_kms_arn" {
  description = "The ARN of the IDP Doc Capture KMS key"
  type        = string
}

variable "pivcac_route53_zone_id" {
  description = "The ID of the PIVCAC Route53 zone"
  type        = string
}

variable "enable_usps_status_updates" {
  type        = bool
  description = <<EOM
Enables recieving emails from USPS for notification updates on in-person proofing.
EOM
  default     = false
}

variable "attempts_api_bucket_arn" {
  description = "The ARN of the attempts API bucket"
  type        = string
}

variable "ssm_policy" {
  description = "The policy to attach to the IAM role. If empty, the resource will not be created."
  type        = string
  default     = ""
}

variable "identity_sms_iam_role_name_idp" {
  description = "IAM role assumed by the IDP for cross-account access into the above identity-sms-* account."
  default     = "idp-pinpoint"
}

variable "ipv4_secondary_cidr" {
  description = "The IPv4 secondary CIDR block associated with the VPC"
  type        = string
}

variable "escrow_bucket_id" {
  description = "The ID of the escrow S3 bucket"
  type        = string
}

variable "cloudfront_oai_iam_arn" {
  description = "The ARN of the IAM identity associated with the CloudFront Origin Access Identity (OAI)"
  type        = string
}

variable "attempts_api_kms_arn" {
  description = "The ARN of the attempts API KMS key"
  type        = string
}

variable "kinesis_bucket_arn" {
  description = "The ARN of the Kinesis bucket"
  type        = string
}

variable "kinesis_kms_key_arn" {
  description = "The ARN of the Kinesis KMS key"
  type        = string
}

variable "slack_events_sns_hook_arn" {
  description = "ARN of SNS topic that will notify the #identity-events/#identity-otherevents channels in Slack"
  type        = string
}

variable "root_domain" {
  description = "DNS domain to use as the root domain, e.g. login.gov"
  type        = string
}

variable "gitlab_env_runner_role_arn" {
  description = "ARN of the GitLab environment runner role"
  type        = string
}

variable "gitlab_enabled" {
  description = "whether to turn on the privatelink to gitlab so that systems can git clone and so on"
  type        = bool
  default     = false
}

variable "usps_updates_sqs_arn" {
  description = "ARN of the SQS queue that will receive USPS status updates"
  type        = string
}