resource "aws_s3_bucket" "athena_query_results"{
  bucket = "aws-athena-query-results-${var.env_name}-${data.aws_caller_identity.current.account_id}-${var.region}"
} 

resource "aws_s3_bucket_acl" "example_bucket_acl" {
  bucket = aws_s3_bucket.athena_query_results.id
  acl    = "private"
}

resource "aws_athena_workgroup" "environment_workgroup" {
  name = "${var.env_name}-workgroup"

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