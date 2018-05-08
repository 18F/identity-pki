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
