# S3 bucket for publishing public data
resource "aws_s3_bucket" "public_reporting_data" {
  # Name truncated as "login-gov-public-reporting-data-ENV.ACCOUNT-REGION is > 63 chars
  bucket        = "login-gov-pubdata-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
  force_destroy = var.force_destroy_idp_static_bucket
  tags = {
    Name = "login-gov-pubdata-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
  }
}

resource "aws_s3_bucket_versioning" "public_reporting_data" {
  bucket = aws_s3_bucket.public_reporting_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_website_configuration" "public_reporting_data" {
  bucket = aws_s3_bucket.public_reporting_data.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "public_reporting_data" {
  bucket = aws_s3_bucket.public_reporting_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "public_reporting_data" {
  bucket = aws_s3_bucket.public_reporting_data.id
  policy = data.aws_iam_policy_document.public_reporting_data_policy.json
}

resource "aws_s3_bucket_logging" "public_reporting_data" {
  bucket = aws_s3_bucket.public_reporting_data.id

  target_bucket = "login-gov.s3-access-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
  target_prefix = "login-gov-idp-static-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/"
}

resource "aws_s3_bucket_lifecycle_configuration" "public_reporting_data" {
  bucket = aws_s3_bucket.public_reporting_data.id

  rule {
    id     = "tf-s3-lifecycle"
    status = "Enabled"
    filter {
      prefix = "/"
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "public_reporting_data" {
  bucket = aws_s3_bucket.public_reporting_data.id

  # Allow CORS for main Login Data site, Cloud.gov preview/other sites, and local development.
  # This is all public data accessed anonymously.
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://data.login.gov", "https://*.app.cloud.gov", "http://localhost:3000"]
    expose_headers  = ["ETag"]
  }
}

module "public_reporting_data_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=e7ad5ef38f724b31911248a74173e9fee3bbf045"

  bucket_name_override = aws_s3_bucket.public_reporting_data.id
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_arn
}

data "aws_iam_policy_document" "public_reporting_data_policy" {
  # IdP and Worker instances can manage content
  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject"
    ]
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.idp.arn,
        aws_iam_role.worker.arn,
      ]
    }
    resources = [
      "arn:aws:s3:::login-gov-pubdata-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}",
      "arn:aws:s3:::login-gov-pubdata-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/*"
    ]
  }

  # Cloudfront access for GET on specific item.  Since we are using the
  # S3 origin the call from CloudFront to S3 uses the S3 API so we do
  # not want to expose permissions like List.
  statement {
    actions = ["s3:GetObject"]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.cloudfront_oai.iam_arn]
    }
    resources = [
      "arn:aws:s3:::login-gov-pubdata-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/*"
    ]
  }
}

