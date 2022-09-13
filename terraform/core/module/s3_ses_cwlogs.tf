resource "aws_s3_bucket" "exported_logs" {
  bucket = "login-gov-ses-feedback-notification-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
  tags = {
    Name = "login-gov-ses-feedback-notification-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
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
  bucket = aws_s3_bucket.exported_logs.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
      #Exporting to S3 buckets encrypted with SSE-KMS is not supported. Exporting to S3 buckets that are encrypted with AES-256 is supported.
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

###Transition between storage class
resource "aws_s3_bucket_lifecycle_configuration" "bucket-config" {
  bucket = aws_s3_bucket.exported_logs.bucket

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

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "INTELLIGENT_TIERING"
    }
  }
}
