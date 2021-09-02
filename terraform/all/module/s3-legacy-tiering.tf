# Preserve legacy/non-TF managed S3 buckets in Intelligent Tiering storage.
# Customize with var.legacy_bucket_list
# Each bucket MUST be imported before this is run!

resource "aws_s3_bucket" "legacy_bucket" {
  for_each = toset(var.legacy_bucket_list)
  
  bucket = each.key
  lifecycle_rule {
    id = "IntelligentTieringArchive"
    enabled = true
    transition {
      storage_class = "INTELLIGENT_TIERING"
      days = 0
    }
    noncurrent_version_transition {
      storage_class = "INTELLIGENT_TIERING"
      days = 0 
    }
  }

  tags = {
    Name        = each.key
    Status      = "ITArchive"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

module "s3_inv_block" {
  for_each = toset(var.legacy_bucket_list)
  source   = "github.com/18F/identity-terraform//s3_config?ref=8f0abe0e3708e2c1ef1c1653ae2b57b378bf8dbf"

  bucket_name_override = each.key
  region               = var.region
  inventory_bucket_arn = module.tf-state.inventory_bucket_arn
}