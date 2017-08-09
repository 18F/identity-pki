variable "region" { default = "us-west-2" }
variable "bucket" { default = "login_dot_gov_tf_state" }
variable "power_users" { type="list" }

provider "aws" {
  region = "${var.region}"
}

# Stub remote config needed for terraform 0.9.*
terraform {
  backend "s3" {
  }
}
