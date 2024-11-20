resource "aws_cloudwatch_log_group" "logarchive_kinesis_lambda" {
  name = "/aws/lambda/logarchive_kinesis"
}

resource "aws_cloudwatch_log_stream" "logarchive_kinesis_lambda" {
  log_group_name = aws_cloudwatch_log_group.logarchive_kinesis_lambda.name
  name           = "LambdaKinesisS3Delivery"
}

module "logarchive_kinesis_lambda" {
  source = "github.com/18F/identity-terraform//null_archive?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/null_archive"

  source_code_filename = "logarchive_kinesis.py"
  source_dir           = "${path.module}/lambda/"

  zip_filename = "logarchive_kinesis.zip"
}

#tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "logarchive_kinesis" {
  filename                       = module.logarchive_kinesis_lambda.zip_output_path
  function_name                  = "logarchive_kinesis"
  description                    = "Function to send Kinesis logarchive data to S3"
  role                           = aws_iam_role.logarchive_kinesis_lambda.arn
  handler                        = "logarchive_kinesis.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 900
  memory_size                    = 1024
  reserved_concurrent_executions = 900
  source_code_hash               = module.logarchive_kinesis_lambda.zip_output_base64sha256
  publish                        = false

  environment {
    variables = {
      CWLogsPrefix = "CloudWatchLogs"
      S3Bucket     = module.logarchive_bucket_primary.bucket_name
      LogS3Keys    = var.log_record_s3_keys
    }
  }

  logging_config {
    log_group  = aws_cloudwatch_log_group.logarchive_kinesis_lambda.name
    log_format = "Text"
  }

  depends_on = [module.logarchive_kinesis_lambda.resource_check]
}

resource "aws_lambda_event_source_mapping" "logarchive_kinesis" {
  event_source_arn               = aws_kinesis_stream_consumer.logarchive.arn
  function_name                  = aws_lambda_function.logarchive_kinesis.arn
  starting_position              = "TRIM_HORIZON"
  batch_size                     = 8
  bisect_batch_on_function_error = true
  parallelization_factor         = 10
  maximum_retry_attempts         = "-1"
  maximum_record_age_in_seconds  = "-1"
  function_response_types        = ["ReportBatchItemFailures"]
}
