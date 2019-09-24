variable "region" {
    description = "AWS region, used for S3 bucket names"
}

variable "state_lock_table" {
    description = "Name of the DynamoDB table to use for state locking with the S3 state backend, e.g. 'terraform-locks'"
}

variable "manage_state_bucket" {
    description = <<EOM
Whether to manage the TF remote state bucket and lock table.
Set this to false if you want to skip this for bootstrapping.
EOM
    default = 1
}

variable "main_account_id" {
    description = <<EOM
Account ID of the main login.gov prod or sandbox account.
This is used to grant access for cross-account role assumption.
EOM
}

variable "pinpoint_app_name" {
    description = "Name of the pinpoint app"
}
