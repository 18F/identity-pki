variable "region" { default = "us-west-2" }
variable "bucket" { default = "login_dot_gov_tf_state" }

variable "power_users" {
    description="List of admin users, used in some IAM roles"
    type="list"
}

variable "certificates_bucket_prefix" {
    description = "Prefix to use when creating the self signed certificates bucket"
    default = "login-gov-internal-certs-test"
}
