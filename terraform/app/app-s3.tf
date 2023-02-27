# S3 bucket for partners to upload and serve logos
# Conditionally create this bucket only if enable_partner_logos_bucket is set to true
resource "aws_s3_bucket" "partner_logos_bucket" {
  count  = var.apps_enabled
  bucket = "login-gov-partner-logos-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
  tags = {
    Name = "login-gov-partner-logos-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
  }
}

resource "aws_s3_bucket_versioning" "partner_logos_bucket" {
  count  = var.apps_enabled
  bucket = aws_s3_bucket.partner_logos_bucket[count.index].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_acl" "partner_logos_bucket" {
  count  = var.apps_enabled
  bucket = aws_s3_bucket.partner_logos_bucket[count.index].id
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "partner_logos_bucket" {
  count  = var.apps_enabled
  bucket = aws_s3_bucket.partner_logos_bucket[count.index].id

  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "partner_logos_bucket" {
  count  = var.apps_enabled
  bucket = aws_s3_bucket.partner_logos_bucket[count.index].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "partner_logos_bucket" {
  count  = var.apps_enabled
  bucket = aws_s3_bucket.partner_logos_bucket[count.index].id
  policy = data.aws_iam_policy_document.partner_logos_bucket_policy[count.index].json
}

resource "aws_s3_bucket_logging" "partner_logos_bucket" {
  count  = var.apps_enabled
  bucket = aws_s3_bucket.partner_logos_bucket[count.index].id

  target_bucket = "login-gov.s3-access-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
  target_prefix = "login-gov-partner-logos-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/"
}

data "aws_iam_policy_document" "partner_logos_bucket_policy" {
  count = var.apps_enabled
  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectVersionAcl",
      "s3:AbortMultipartUpload",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectVersionAcl",
      "s3:ListBucket",
      "s3:DeleteObject",
    ]
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.app[count.index].arn,
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/PowerUser",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/FullAdministrator",
      ]
    }

    resources = [
      "arn:aws:s3:::login-gov-partner-logos-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}",
      "arn:aws:s3:::login-gov-partner-logos-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/*",
    ]
  }
}

module "partner_logos_bucket_config" {
  count  = var.apps_enabled
  source = "github.com/18F/identity-terraform//s3_config?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/s3_config"

  bucket_name_override = aws_s3_bucket.partner_logos_bucket[count.index].id
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_arn
  block_public_access  = false
}
