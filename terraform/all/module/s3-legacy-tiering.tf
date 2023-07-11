# Preserve legacy/non-TF managed S3 buckets in Intelligent Tiering storage.
# Customize with var.legacy_bucket_list
# Each bucket MUST be imported before this is run!

resource "aws_s3_bucket" "legacy_bucket" {
  for_each = toset(var.legacy_bucket_list)

  bucket = each.key
  tags = {
    Name   = each.key
    Status = "ITArchive"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "legacy_bucket" {
  for_each = toset(var.legacy_bucket_list)
  bucket   = each.key

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "legacy_bucket" {
  for_each = toset(var.legacy_bucket_list)
  bucket   = each.key

  rule {
    id     = "IntelligentTieringArchive"
    status = "Enabled"
    transition {
      storage_class = "INTELLIGENT_TIERING"
      days          = 0
    }
    noncurrent_version_transition {
      storage_class   = "INTELLIGENT_TIERING"
      noncurrent_days = 0
    }
  }
}

module "s3_inv_block" {
  for_each = toset(var.legacy_bucket_list)
  source   = "github.com/18F/identity-terraform//s3_config?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/s3_config"

  bucket_name_override = each.key
  region               = var.region
  inventory_bucket_arn = module.tf_state_uw2.inventory_bucket_arn
}