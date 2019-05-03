variable "region" { default = "us-west-2" }
variable "bucket" { default = "login_dot_gov_tf_state" }

variable "state_lock_table" {
    description = "Name of the DynamoDB table to use for state locking with the S3 state backend, e.g. 'terraform-locks'"
}

variable "power_users" {
    description="List of admin users, used in some IAM roles"
    type="list"
}

variable "certificates_bucket_prefix" {
    description = "Prefix to use when creating the self signed certificates bucket"
    default = "login-gov-internal-certs-test"
}

variable "manage_state_bucket" {
    description = <<EOM
Whether to manage the TF remote state bucket and lock table.
Set this to false if you want to skip this for bootstrapping.
EOM
    default = 1
}

variable "slack_events_sns_hook_arn" {
    description = "ARN of SNS topic that will notify the #identity-events/#identity-otherevents channels in Slack"
}

variable "master_account_id" {
    default = "340731855345"
    description = "AWS Account ID for master account"
}
