# AWS provider is inherited from per-env main.tf rather than defined here, due
# to https://github.com/hashicorp/terraform/issues/13018

locals {
  password_length = 32
  s3_log_bucket   = module.tf-state.s3_log_bucket
}

data "aws_caller_identity" "current" {
}

module "iam_account" {
  source        = "terraform-aws-modules/iam/aws//modules/iam-account"
  version       = "~> 2.0"
  account_alias = "login-master"

  allow_users_to_change_password = true
  create_account_password_policy = true
  max_password_age               = 90
  minimum_password_length        = local.password_length
  password_reuse_prevention      = 1
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  require_uppercase_characters   = true
}

resource "aws_s3_account_public_access_block" "s3_limits" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "cloudtrail" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "s3:GetBucketAcl",
    ]
    resources = [
      "arn:aws:s3:::login-gov-cloudtrail-${data.aws_caller_identity.current.account_id}",
    ]
  }
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::login-gov-cloudtrail-${data.aws_caller_identity.current.account_id}/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values = [
        "bucket-owner-full-control",
      ]
    }
  }
}

resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "login-gov-cloudtrail-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  policy = data.aws_iam_policy_document.cloudtrail.json

  lifecycle_rule {
    id      = "logexpire"
    enabled = true
    prefix  = ""

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

# create cloudwatch log group for cloudtrail
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name = "CloudTrail/logs"
}

data "aws_iam_policy_document" "cloudtrail_assume" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "cloudtrail.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "cloudtrail_cloudwatch" {
  name               = "CloudTrailCloudWatch"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_assume.json
}

data "aws_iam_policy_document" "cloudwatch_perms_cloudtrail" {
  statement {
    sid    = "CloudWatch"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "${aws_cloudwatch_log_group.cloudtrail.arn}:log-stream:*",
    ]
  }
}

resource "aws_iam_role_policy" "cloudwatch_perms_cloudtrail" {
  name   = "CloudWatch"
  role   = aws_iam_role.cloudtrail_cloudwatch.name
  policy = data.aws_iam_policy_document.cloudwatch_perms_cloudtrail.json
}

resource "aws_cloudtrail" "cloudtrail" {
  enable_log_file_validation    = true
  include_global_service_events = true
  is_multi_region_trail         = true
  name                          = "login-gov-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
}

# Module that manages the terraform remote state bucket and creates the S3 logs bucket
module "tf-state" {
  source = "github.com/18F/identity-terraform//state_bucket?ref=d111d1df1e47671313430b6f1492735ae45767bf"
  region = var.region
}

module "main_secrets_bucket" {
  source              = "../../modules/secrets_bucket"
  logs_bucket         = local.s3_log_bucket
  secrets_bucket_type = "secrets"
  bucket_name_prefix  = "login-gov"
}

output "main_secrets_bucket" {
  value = module.main_secrets_bucket.bucket_name
}
