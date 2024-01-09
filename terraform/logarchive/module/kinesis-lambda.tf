resource "aws_cloudwatch_log_group" "logarchive_kinesis_lambda" {
  name = "/aws/lambda/${local.aws_alias}-${data.aws_region.current.name}"
}

resource "aws_cloudwatch_log_stream" "logarchive_kinesis_lambda" {
  log_group_name = aws_cloudwatch_log_group.logarchive_kinesis_lambda.name
  name           = "LambdaKinesisS3Delivery"
}

resource "aws_kinesis_stream" "logarchive" {
  name             = "${local.aws_alias}-${data.aws_region.current.name}"
  shard_count      = 1
  retention_period = 24
}

module "logarchive_kinesis_lambda" {
  source = "github.com/18F/identity-terraform//null_archive?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/null_archive"

  source_code_filename = "kinesis_logarchive.py"
  source_dir           = "${path.module}/lambda/"

  zip_filename = "kinesis_logarchive.zip"
}

#tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "kinesis_logarchive" {
  filename         = module.logarchive_kinesis_lambda.zip_output_path
  function_name    = "kinesis_logarchive"
  description      = "Lambda function to remove old or unused AMIs"
  role             = aws_iam_role.logarchive_kinesis_lambda.arn
  handler          = "kinesis_logarchive.lambda_handler"
  runtime          = "python3.9"
  timeout          = 300
  source_code_hash = module.logarchive_kinesis_lambda.zip_output_base64sha256
  publish          = false

  environment {
    variables = {
      CWLogsPrefix = "kinesis"
      S3Bucket     = module.logarchive_bucket_primary.bucket_name
    }
  }

  depends_on = [module.logarchive_kinesis_lambda.resource_check]
}
