provider "aws" {
  region = "${var.region}"
}

# Stub remote config needed for terraform 0.9.*
terraform {
  backend "s3" {
  }
}

# This policy can be used to allow anybody to join the role
data "aws_iam_policy_document" "assume_role_from_vpc" {
  statement {
    sid = "allowVPC"
    actions = [
      "sts:AssumeRole"
    ]
    principals = {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_caller_identity" "current" {}
