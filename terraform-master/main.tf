provider "aws" {
  region = "${var.region}"
}

locals {
    password_length = 32
}

data "aws_caller_identity" "current" {}

module "iam_account" {
    source = "terraform-aws-modules/iam/aws//modules/iam-account"
    version = "~> 1.0"
    account_alias = "18f-identity-master"

    allow_users_to_change_password = true
    create_account_password_policy = true
    max_password_age = 90
    minimum_password_length = "${local.password_length}"
    password_reuse_prevention = true
    require_lowercase_characters = true
    require_numbers = true
    require_symbols = true
    require_uppercase_characters = true
}

resource "aws_s3_account_public_access_block" "s3_limits" {
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}

data "aws_iam_policy_document" "cloudtrail" {
  statement {
    principals = {
      type = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "s3:GetBucketAcl"
    ]
    resources = [
      "arn:aws:s3:::login-gov-cloudtrail-${data.aws_caller_identity.current.account_id}"
    ]
  }
  statement {
    principals = {
      type = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::login-gov-cloudtrail-${data.aws_caller_identity.current.account_id}/*"
    ]
    condition {
      test = "StringEquals"
      variable = "s3:x-amz-acl"
      values = [
        "bucket-owner-full-control"
      ]
    }
  }
}

resource "aws_s3_bucket" "cloudtrail" {
  bucket = "login-gov-cloudtrail-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  policy = "${data.aws_iam_policy_document.cloudtrail.json}"

  lifecycle_rule {
    id = "logexpire"
    enabled = true
    prefix = ""

    expiration {
      days = 30
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}

resource "aws_cloudtrail" "cloudtrail" {
  enable_log_file_validation = true
  include_global_service_events = false
  name = "login-gov-cloudtrail"
  s3_bucket_name = "${aws_s3_bucket.cloudtrail.id}"
}
