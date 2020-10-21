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
}

module "s3_inv_block" {
  for_each = toset(var.legacy_bucket_list)
  source   = "github.com/18F/identity-terraform//s3_config?ref=847c2168dc7dabb4c53b2ae93e944e05f04dbcd7"

  bucket_name_override = each.key
  region               = var.region
  inventory_bucket_arn = module.tf-state.inventory_bucket_arn
}