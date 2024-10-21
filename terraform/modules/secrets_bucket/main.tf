terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "secrets" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = {
    Name        = var.bucket_name_prefix
    Environment = "All"
  }
}

resource "aws_s3_bucket_ownership_controls" "secrets" {
  bucket = aws_s3_bucket.secrets.id

  rule {
    object_ownership = var.object_ownership
  }
}

resource "aws_s3_bucket_acl" "secrets" {
  count = var.object_ownership == "BucketOwnerEnforced" ? 0 : 1

  bucket = aws_s3_bucket.secrets.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.secrets]
}

resource "aws_s3_bucket_versioning" "secrets" {
  bucket = aws_s3_bucket.secrets.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secrets" {
  bucket = aws_s3_bucket.secrets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.sse_algorithm
    }
  }
}

resource "aws_s3_bucket_policy" "secrets" {
  bucket = aws_s3_bucket.secrets.id
  policy = data.aws_iam_policy_document.secret_bucket_policy.json
}

data "aws_iam_policy_document" "secret_bucket_policy" {
  source_policy_documents = var.policy == "" ? [data.aws_iam_policy_document.s3_secure_connections.json] : [var.policy, data.aws_iam_policy_document.s3_secure_connections.json]
}

data "aws_iam_policy_document" "s3_secure_connections" {
  statement {
    sid = "S3DenyNonSecureConnections"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:*",
    ]
    effect = "Deny"
    resources = [
      aws_s3_bucket.secrets.arn,
      "${aws_s3_bucket.secrets.arn}/*"
    ]
    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
  }
}

moved {
  from = aws_s3_bucket_logging.secrets
  to   = module.secrets_bucket_config.aws_s3_bucket_logging.access_logging
}

module "secrets_bucket_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=88438f7586c277c0a85995e90efbbc9db563502d"
  #source     = "../../../../identity-terraform/s3_config"
  depends_on = [aws_s3_bucket.secrets]

  bucket_name_prefix   = var.bucket_name_prefix
  bucket_name          = var.secrets_bucket_type
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_arn
  logging_bucket_id    = var.logs_bucket
}
