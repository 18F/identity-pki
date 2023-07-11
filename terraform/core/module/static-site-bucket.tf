# Creates a S3 bucket and matching OAI for any account-wide
# static site needs, like mta-sts.DOMAIN

# Note - There is a 100 OAI limit per-account - A switch
# to one account wide OAI may make sense when we are continerized.
resource "aws_cloudfront_origin_access_identity" "cloudfront_oai" {
  comment = "${var.root_domain} - CloudFront access to static S3 bucket"
}

output "cloudfront_oai_arn" {
  value = aws_cloudfront_origin_access_identity.cloudfront_oai.iam_arn
}

output "cloudfront_oai_path" {
  value = aws_cloudfront_origin_access_identity.cloudfront_oai.cloudfront_access_identity_path
}

# S3 bucket for static assets
resource "aws_s3_bucket" "account_static_bucket" {
  bucket = "login-gov-account-static.${data.aws_caller_identity.current.account_id}-${var.region}"

  tags = {
    Name = "login-gov-account-static.${data.aws_caller_identity.current.account_id}-${var.region}"
  }
}

# Versioning in place, though all resources in this bucket should be
# in repos.  Deleted versions purged in 30 days.
resource "aws_s3_bucket_versioning" "account_static_bucket" {
  bucket = aws_s3_bucket.account_static_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_website_configuration" "account_static_bucket" {
  bucket = aws_s3_bucket.account_static_bucket.id

  index_document {
    suffix = "index.html"
  }
}


resource "aws_s3_bucket_server_side_encryption_configuration" "account_static_bucket" {
  bucket = aws_s3_bucket.account_static_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "account_static_bucket" {
  bucket = aws_s3_bucket.account_static_bucket.id
  policy = data.aws_iam_policy_document.account_static_bucket_policy.json
}

resource "aws_s3_bucket_logging" "account_static_bucket" {
  bucket = aws_s3_bucket.account_static_bucket.id

  target_bucket = local.s3_logs_bucket_uw2
  target_prefix = "login-gov-account-static.${data.aws_caller_identity.current.account_id}-${var.region}/"
}

resource "aws_s3_bucket_lifecycle_configuration" "account_static_bucket" {
  bucket = aws_s3_bucket.account_static_bucket.id

  rule {
    id     = "noncurrent_version_expiration"
    status = "Enabled"
    filter {
      prefix = "/"
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# resource "aws_s3_bucket_cors_configuration" "account_static_bucket" {
#   bucket = aws_s3_bucket.account_static_bucket
# 
#   cors_rule {
#     allowed_headers = ["*"]
#     allowed_methods = ["GET"]
#     allowed_origins = ["https://*.${var.root_domain}"]
#     expose_headers  = ["ETag"]
#   }
# }

module "account_static_bucket_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/s3_config"

  bucket_name_override = aws_s3_bucket.account_static_bucket.id
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_uw2_arn
}

data "aws_iam_policy_document" "account_static_bucket_policy" {
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
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Terraform"
      ]
    }
    resources = [
      "arn:aws:s3:::login-gov-account-static.${data.aws_caller_identity.current.account_id}-${var.region}",
      "arn:aws:s3:::login-gov-account-static.${data.aws_caller_identity.current.account_id}-${var.region}/*"
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
      "arn:aws:s3:::login-gov-account-static.${data.aws_caller_identity.current.account_id}-${var.region}/*"
    ]
  }
}
