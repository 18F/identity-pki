resource "aws_s3_bucket" "reports" {
  bucket = "${local.bucket_name_prefix}.reports.${data.aws_caller_identity.current.account_id}-${var.region}"
}

resource "aws_s3_bucket_acl" "reports" {
  bucket = aws_s3_bucket.reports.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "reports" {
  bucket = aws_s3_bucket.reports.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "reports" {
  bucket = aws_s3_bucket.reports.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "reports" {
  bucket = aws_s3_bucket.reports.id

  target_bucket = local.s3_logs_bucket
  target_prefix = "${aws_s3_bucket.reports.id}/"
}

resource "aws_s3_bucket_lifecycle_configuration" "reports" {
  bucket = aws_s3_bucket.reports.id

  rule {
    id     = "aging"
    status = "Enabled"

    filter {
      prefix = "/"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

module "s3_reports_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/s3_config"

  bucket_name_prefix   = local.bucket_name_prefix
  bucket_name          = "reports"
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_uw2_arn
  block_public_access  = true
}
