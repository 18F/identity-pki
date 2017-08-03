variable "region" { default = "us-west-2" }

provider "aws" {
  region = "${var.region}"
}

# Stub remote config needed for terraform 0.9.*
terraform {
  backend "s3" {
  }
}
