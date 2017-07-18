variable "region" { default="us-west-2" }

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
    sid = "AllowSecretsBucketIntegrationTest"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
       "arn:aws:s3:::login-gov-secrets-test/integration/",
       "arn:aws:s3:::login-gov-secrets-test/integration/*",
       "arn:aws:s3:::login-gov-secrets/integration/",
       "arn:aws:s3:::login-gov-secrets/integration/*"
    ]
  }
}

resource "aws_iam_role" "integration" {
  name = "integration_test_role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_from_vpc.json}"
}

resource "aws_iam_role_policy" "integration" {
  name = "integration_test_secrets_role_policy"
  role = "${aws_iam_role.integration.id}"
  policy = "${data.aws_iam_policy_document.secrets_role_policy.json}"
}

resource "aws_iam_instance_profile" "integration" {
  name = "integration_test_instance_profile"
  roles = ["${aws_iam_role.integration.name}"]
}
