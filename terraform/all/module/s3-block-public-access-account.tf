# Restict public S3 access
# See https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html
resource "aws_s3_account_public_access_block" "account" {
  block_public_acls       = var.s3_block_all_public_access
  block_public_policy     = var.s3_block_all_public_access
  ignore_public_acls      = var.s3_block_all_public_access
  restrict_public_buckets = var.s3_block_all_public_access
}
