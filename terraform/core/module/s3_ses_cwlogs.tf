locals {
  exported_logs_bucket = join(".", [
    "login-gov-ses-feedback-notification-logs",
    "${data.aws_caller_identity.current.account_id}-${var.region}"
  ])
}

resource "aws_s3_bucket" "exported_logs" {
  bucket = local.exported_logs_bucket
  tags = {
    Name = local.exported_logs_bucket
  }

  # destroy the bucket in two steps
  # -> comment prevent_destroy = true
  # -> uncomment force_destroy = true
  # terraform apply -target=aws_s3_bucket.exported_logs 

  #force_destroy = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.exported_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
      # Exporting to S3 buckets encrypted with SSE-KMS is not supported.
      # Exporting to S3 buckets that are encrypted with AES-256 is supported.
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "object_ownership" {
  bucket = aws_s3_bucket.exported_logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.exported_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "allow_cw_logs" {
  bucket = aws_s3_bucket.exported_logs.id
  policy = data.aws_iam_policy_document.allow_cw_logs.json
}

data "aws_iam_policy_document" "allow_cw_logs" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl"
    ]

    resources = [
      aws_s3_bucket.exported_logs.arn
    ]
  }
  statement {
    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.exported_logs.arn}/*",
    ]

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

### Transition between storage class
resource "aws_s3_bucket_lifecycle_configuration" "bucket-config" {
  bucket = aws_s3_bucket.exported_logs.id

  rule {
    id = "archival"

    filter {
      and {
        prefix = "/"

        tags = {
          rule      = "archival"
          autoclean = "false"
        }
      }
    }

    status = "Enabled"

    expiration {
      days = 90
    }
  }
}

### SES feedback notification evaluation
module "ses_feedback_notification" {
  source                = "../../modules/eval_ses_feedback_notification"
  ses_verified_identity = var.root_domain
}

resource "aws_sns_topic_subscription" "ses_feedback_subscription_complaint" {
  count = var.root_domain == "login.gov" ? 1 : 0 # only create in prod

  topic_arn = module.ses_feedback_notification.sns_for_ses_compliant_notifications
  protocol  = "email"
  endpoint  = "email-complaints@${var.root_domain}"
}

### Exporting SES logs to S3
module "export_to_s3" {
  source = "../../modules/export_cwlogs_to_s3"

  depends_on = [
    aws_s3_bucket.exported_logs
  ]

  cw_log_group = [module.ses_feedback_notification.ses_feedback_eval_lambda_loggroup]
  s3_bucket    = aws_s3_bucket.exported_logs.id
}

###Capturing SES Events to CW logs using configuration steps
module "publish-ses-events-to-cw-logs-using-configsets" {
  source                = "../../modules/publish_ses_events_to_cw_logs"
  ses_verified_identity = var.root_domain
}