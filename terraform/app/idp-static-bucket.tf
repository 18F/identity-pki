# S3 bucket for static assets
locals {
  bucket_name = "login-gov-idp-static-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
}

resource "aws_s3_bucket" "idp_static_bucket" {
  # Conditionally create this bucket only if enable_idp_assets_bucket is set to true
  count = var.enable_idp_static_bucket ? 1 : 0

  bucket = local.bucket_name

  force_destroy = var.force_destroy_idp_static_bucket

  logging {
    target_bucket = "login-gov.s3-access-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    target_prefix = "${local.bucket_name}/"
  }

  tags = {
    Name = local.bucket_name
  }

  website {
    index_document = "index.html"
  }

  policy = data.aws_iam_policy_document.idp_static_bucket_policy.json

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  # Versioning in place, though all resources in this bucket should be
  # in repos.  Deleted versions purged in 30 days.
  versioning {
    enabled = true
  }

  lifecycle_rule {
    prefix  = "/"
    enabled = true

    noncurrent_version_expiration {
      days = 30
    }
  }

  # Allow JS in subdomains, including idp., to access fonts/etc
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://*.${var.root_domain}"]
    expose_headers  = ["ETag"]
  }
}

module "idp_static_bucket_config" {
  count  = var.enable_idp_static_bucket ? 1 : 0
  source = "github.com/18F/identity-terraform//s3_config?ref=a6261020a94b77b08eedf92a068832f21723f7a2"

  bucket_name_override = aws_s3_bucket.idp_static_bucket[0].id
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_arn
}

data "aws_iam_policy_document" "idp_static_bucket_policy" {
  source_json = data.aws_iam_policy_document.cross_account.json

  # IdP and PowerUser can manage items
  statement {
    sid = "EC2PowerUserPermission"
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
        aws_iam_role.migration.arn,
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/PowerUser"
      ]
    }
    resources = [
      "arn:aws:s3:::${local.bucket_name}",
      "arn:aws:s3:::${local.bucket_name}/*"
    ]
  }

  # Cloudfront access for GET on specific item.  Since we are using the
  # S3 origin the call from CloudFront to S3 uses the S3 API so we do
  # not want to expose permissions like List.
  statement {
    sid     = "CloudFrontGET"
    actions = ["s3:GetObject"]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.cloudfront_oai.iam_arn]
    }
    resources = [
      "arn:aws:s3:::${local.bucket_name}/*"
    ]
  }
}

data "aws_iam_policy_document" "cross_account" {
  dynamic "statement" {
    for_each = toset(var.idp_static_bucket_cross_account_access)

    content {
      actions = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ]
      principals {
        type = "AWS"
        identifiers = [
          statement.key
        ]
      }
      resources = [
        "arn:aws:s3:::${local.bucket_name}/*",
        "arn:aws:s3:::${local.bucket_name}"
      ]
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "idp_static_bucket" {
  count  = var.enable_idp_static_bucket ? 1 : 0
  bucket = aws_s3_bucket.idp_static_bucket[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
