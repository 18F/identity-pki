# S3 bucket for static assets
locals {
  bucket_name = "login-gov-idp-static-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
}

resource "aws_s3_bucket" "idp_static_bucket" {
  # Conditionally create this bucket only if enable_idp_assets_bucket is set to true
  count = var.enable_idp_static_bucket ? 1 : 0

  bucket        = local.bucket_name
  force_destroy = var.force_destroy_idp_static_bucket
  tags = {
    Name = local.bucket_name
  }


  # Versioning in place, though all resources in this bucket should be
  # in repos.  Deleted versions purged in 30 days.
}

resource "aws_s3_bucket_versioning" "idp_static_bucket" {
  count  = var.enable_idp_static_bucket ? 1 : 0
  bucket = aws_s3_bucket.idp_static_bucket[count.index].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_website_configuration" "idp_static_bucket" {
  count  = var.enable_idp_static_bucket ? 1 : 0
  bucket = aws_s3_bucket.idp_static_bucket[count.index].id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "idp_static_bucket" {
  count  = var.enable_idp_static_bucket ? 1 : 0
  bucket = aws_s3_bucket.idp_static_bucket[count.index].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "idp_static_bucket" {
  count  = var.enable_idp_static_bucket ? 1 : 0
  bucket = aws_s3_bucket.idp_static_bucket[count.index].id
  policy = data.aws_iam_policy_document.idp_static_bucket_policy.json
}

resource "aws_s3_bucket_logging" "idp_static_bucket" {
  count  = var.enable_idp_static_bucket ? 1 : 0
  bucket = aws_s3_bucket.idp_static_bucket[count.index].id

  target_bucket = "login-gov.s3-access-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
  target_prefix = "${local.bucket_name}/"
}

resource "aws_s3_bucket_lifecycle_configuration" "idp_static_bucket" {
  count  = var.enable_idp_static_bucket ? 1 : 0
  bucket = aws_s3_bucket.idp_static_bucket[count.index].id

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


resource "aws_s3_bucket_cors_configuration" "idp_static_bucket" {
  count  = var.enable_idp_static_bucket ? 1 : 0
  bucket = aws_s3_bucket.idp_static_bucket[count.index].id

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
  source = "github.com/18F/identity-terraform//s3_config?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/s3_config"

  bucket_name_override = aws_s3_bucket.idp_static_bucket[count.index].id
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_arn
}

data "aws_iam_policy_document" "idp_static_bucket_policy" {
  source_policy_documents = [data.aws_iam_policy_document.cross_account.json]

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
  bucket = aws_s3_bucket.idp_static_bucket[count.index].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Populates the custom error/maintenance pages into the static bucket used by cloudfront
resource "aws_s3_object" "cloudfront_custom_pages" {
  depends_on             = [aws_s3_bucket.idp_static_bucket[0]]
  for_each               = var.cloudfront_custom_pages
  key                    = each.key
  bucket                 = aws_s3_bucket.idp_static_bucket[0].id
  source                 = each.value
  content_type           = "text/html"
  server_side_encryption = "AES256"
  etag                   = filemd5(each.value)
}
