data "aws_caller_identity" "current" {
}

locals {
  bucket_name          = "${var.bucket_name_prefix}.${var.secrets_bucket_type}.${data.aws_caller_identity.current.account_id}-${var.region}"
  inventory_bucket_arn = "arn:aws:s3:::${var.bucket_name_prefix}.s3-inventory.${data.aws_caller_identity.current.account_id}-${var.region}"
}

resource "aws_s3_bucket" "secrets" {
  bucket        = local.bucket_name
  acl           = "private"
  force_destroy = var.force_destroy

  policy = ""

  tags = {
    Name        = var.bucket_name_prefix
    Environment = "All"
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = var.logs_bucket
    target_prefix = "${local.bucket_name}/"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}

module "secrets_bucket_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=36ecdc74c3436585568fab7abddb3336cec35d93"

  bucket_name_prefix   = var.bucket_name_prefix
  bucket_name          = var.secrets_bucket_type
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_arn
}
