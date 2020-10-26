data "aws_iam_policy_document" "cloudtrail" {
  statement {
    principals {
      type        = "Service"
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
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::login-gov-cloudtrail-${data.aws_caller_identity.current.account_id}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = [
        "bucket-owner-full-control"
      ]
    }
  }
}

data "aws_iam_policy_document" "cloudtrail_assume_role" {
  statement {
    sid = "CloudTrailAssumeRole"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}

data "aws_iam_policy_document" "cloudtrail_cloudwatch_logs" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.cloudtrail_default.arn}:log-stream:${data.aws_caller_identity.current.account_id}_CloudTrail_${var.region}*"
    ]
  }
}

resource "aws_s3_bucket" "cloudtrail" {
  bucket = "login-gov-cloudtrail-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  policy = data.aws_iam_policy_document.cloudtrail.json

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "logexpire"
    enabled = true
    prefix  = ""

    transition {
      days = 90
      storage_class = "STANDARD_IA" 
    }

    transition {
      days = 365
      storage_class = "GLACIER"
    }

    expiration {
      days = 2190
    }

    noncurrent_version_transition {
      days = 90 
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_transition {
      days = 365
      storage_class = "GLACIER"
    }

    noncurrent_version_expiration {
      days = 2190
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  logging {
    target_bucket = "login-gov.s3-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    target_prefix = "login-gov-cloudtrail-${data.aws_caller_identity.current.account_id}"
  }
}

module "cloudtrail_bucket_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=897cd9f749ead05a97b0f904a5dedfe83d9a9566"

  bucket_name_override = aws_s3_bucket.cloudtrail.id
  inventory_bucket_arn = module.tf-state.inventory_bucket_arn
}

resource "aws_cloudwatch_log_group" "cloudtrail_default" {
  name = "CloudTrail/DefaultLogGroup"
  retention_in_days = 90
}

resource "aws_iam_role" "cloudtrail_cloudwatch_logs" {
  name               = "CloudTrail_CloudWatchLogs_Role"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_assume_role.json
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch_logs" {
  name   = "CloudTrail_CloudWatchLogs_Role"
  role   = aws_iam_role.cloudtrail_cloudwatch_logs.id
  policy = data.aws_iam_policy_document.cloudtrail_cloudwatch_logs.json
}

resource "aws_cloudtrail" "cloudtrail" {
  name                          = "login-gov-cloudtrail"
  enable_log_file_validation    = true
  enable_logging                = true
  include_global_service_events = true
  is_multi_region_trail         = true
  is_organization_trail         = false
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail_default.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cloudwatch_logs.arn

  dynamic "event_selector" {
    for_each = var.cloudtrail_event_selectors
    content {
      include_management_events  = lookup(event_selector.value, "include_management_events", false)
      read_write_type            = lookup(event_selector.value, "read_write_type", "ReadOnly")

      dynamic "data_resource" {
        for_each = flatten(list(lookup(event_selector.value, "data_resources", [])))
        content {
          type   = lookup(data_resource.value, "type", null)
          values = lookup(data_resource.value, "values", [])
        }
      }
    }
  }
}