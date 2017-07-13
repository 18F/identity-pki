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

# this policy can allow any node/host to access the s3 secrets bucket
data "aws_iam_policy_document" "secrets_role_policy" {
  statement {
    # sid = "AllowSecretsBucket"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::login-gov-secrets-test/common/",
      "arn:aws:s3:::login-gov-secrets-test/common/*",
      "arn:aws:s3:::login-gov-secrets/common/",
      "arn:aws:s3:::login-gov-secrets/common/*",
      "arn:aws:s3:::login-gov-secrets-test/${var.env_name}/",
      "arn:aws:s3:::login-gov-secrets-test/${var.env_name}/*",
      "arn:aws:s3:::login-gov-secrets/${var.env_name}/",
      "arn:aws:s3:::login-gov-secrets/${var.env_name}/*"
    ]
  }
}

# this policy can allow any node/host to access the s3 secrets bucket
data "aws_iam_policy_document" "secrets_role_policy" {
  statement {
   # sid = "AllowSecretsBucket"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
       "arn:aws:s3:::login-gov-secrets-test/${var.env_name}/",
       "arn:aws:s3:::login-gov-secrets-test/${var.env_name}/*",
       "arn:aws:s3:::login-gov-secrets/${var.env_name}/",
       "arn:aws:s3:::login-gov-secrets/${var.env_name}/*"
    ]
  }
}
