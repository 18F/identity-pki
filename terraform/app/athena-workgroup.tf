resource "aws_s3_bucket" "athena_query_results"{
  bucket = "aws-athena-query-results-${var.env_name}-${data.aws_caller_identity.current.account_id}-${var.region}"
} 

resource "aws_s3_bucket_acl" "athena_query_results_acl" {
  bucket = aws_s3_bucket.athena_query_results.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "athena_query_results_public_access_block" {
  bucket =aws_s3_bucket.athena_query_results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "athena_query_results_sse" {
  bucket = aws_s3_bucket.athena_query_results.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = module.kinesis-firehose.kinesis_firehose_stream_bucket_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_athena_workgroup" "environment_workgroup" {
  name = "${var.env_name}-workgroup"
  force_destroy = true

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_query_results.bucket}/output/"

      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = module.kinesis-firehose.kinesis_firehose_stream_bucket_kms_key.arn
      }
    }
  }
}