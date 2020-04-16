# S3 bucket for static assets
resource "aws_s3_bucket" "idp_static_bucket" {
  # Conditionally create this bucket only if enable_idp_assets_bucket is set to true
  count = var.enable_idp_static_bucket ? 1 : 0

  bucket = "login-gov-idp-static-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
  acl    = "public-read"

  force_destroy = var.force_destroy_idp_static_bucket

  logging {
    target_bucket = "login-gov.s3-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    target_prefix = "/${var.env_name}/s3-access-logs/login-gov-idp-static/"
  }

  tags = {
    Name = "login-gov-idp-static-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
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

  # Assets bear unique names and should not require versioning
  versioning {
    enabled = false
  }

  # Allow JS in subdomains, including idp., to access fonts/etc
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://*.${var.root_domain}"]
    expose_headers  = ["ETag"]
  }
}

data "aws_iam_policy_document" "idp_static_bucket_policy" {
  # IdP and AppDev can manage items
  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject"
    ]
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.idp.arn,
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AppDev"
      ]
    }
    resources = [
      "arn:aws:s3:::login-gov-idp-static-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}",
      "arn:aws:s3:::login-gov-idp-static-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/*"
    ]
  }

  # Public read access
  statement {
    actions = ["s3:GetObject"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      "arn:aws:s3:::login-gov-idp-static-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/*"
    ]
  }
}
