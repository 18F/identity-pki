resource "aws_s3_bucket" "athena_query_results" {
  bucket = join(".", [
    "login-gov-athena-queries-${var.env_name}",
    "${data.aws_caller_identity.current.account_id}-${var.region}"
  ])
}

resource "aws_s3_bucket_ownership_controls" "athena_query_results" {
  bucket = aws_s3_bucket.athena_query_results.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "athena_query_results" {
  bucket = aws_s3_bucket.athena_query_results.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.athena_query_results]
}

resource "aws_s3_bucket_public_access_block" "athena_query_results" {
  bucket = aws_s3_bucket.athena_query_results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "athena_query_results" {
  bucket = aws_s3_bucket.athena_query_results.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
