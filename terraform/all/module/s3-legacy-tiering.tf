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