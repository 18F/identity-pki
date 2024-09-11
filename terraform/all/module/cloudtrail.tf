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
      values = [
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
  bucket        = "login-gov-cloudtrail-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = data.aws_iam_policy_document.cloudtrail.json
}

moved {
  from = aws_s3_bucket_logging.cloudtrail
  to   = module.cloudtrail_bucket_config.aws_s3_bucket_logging.access_logging
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    id     = "logexpire"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    expiration {
      days = 2190
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 365
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 2190
    }
  }
}

module "cloudtrail_bucket_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=188d82b9e9b7423f1a71988413ec5899d31807fe"
  #source = "../../../../identity-terraform/s3_config"

  bucket_name_override = aws_s3_bucket.cloudtrail.id
  inventory_bucket_arn = module.tf_state_uw2.inventory_bucket_arn
  logging_bucket_id    = module.tf_state_uw2.s3_access_log_bucket
}

resource "aws_cloudwatch_log_group" "cloudtrail_default" {
  name              = "CloudTrail/DefaultLogGroup"
  retention_in_days = 365
  skip_destroy      = true
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
      include_management_events = lookup(event_selector.value, "include_management_events", false)
      read_write_type           = lookup(event_selector.value, "read_write_type", "ReadOnly")

      dynamic "data_resource" {
        for_each = flatten(lookup(event_selector.value, "data_resources", []))
        content {
          type   = lookup(data_resource.value, "type", null)
          values = lookup(data_resource.value, "values", [])
        }
      }
    }
  }

  depends_on = [
    aws_s3_bucket_policy.cloudtrail,
    aws_cloudwatch_log_group.cloudtrail_default
  ]
}

resource "aws_cloudwatch_event_rule" "cloudtrail_logging_disabled" {
  name          = "cloudtrail-logging-disabled"
  description   = "Cloudtrail Logging Disabled"
  event_pattern = <<EOF
{
  "detail-type": ["AWS API Call via CloudTrail"],
  "source": ["aws.cloudtrail"],
  "detail": {
    "eventSource": ["cloudtrail.amazonaws.com"],
    "eventName": ["DeleteTrail", "StopLogging"]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "cloudtrail_logging_disabled" {
  rule      = aws_cloudwatch_event_rule.cloudtrail_logging_disabled.name
  target_id = "SendToSlack"
  arn       = aws_sns_topic.slack_usw2["events"].arn
}

