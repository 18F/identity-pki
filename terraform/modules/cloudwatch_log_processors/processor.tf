module "lambda_code" {
  source = "github.com/18F/identity-terraform//null_archive?ref=b4eb8ffd4f46539b35b31833237d7a0413adc029"

  source_code_filename = "${var.log_processor_lambda}.py"
  source_dir           = "${path.module}/src/"
  zip_filename         = "${var.log_processor_lambda}.zip"
}

resource "aws_lambda_function" "log_processor_lambda" {
  filename         = module.lambda_code.zip_output_path
  function_name    = "${var.env_name}-${var.lambda_name}"
  description      = var.lambda_description
  role             = aws_iam_role.cloudwatch_log_processor_lambda.arn
  handler          = "${var.log_processor_lambda}.lambda_handler"
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory
  source_code_hash = module.lambda_code.zip_output_base64sha256
  publish          = false

  depends_on = [module.lambda_code.resource_check]
}

resource "aws_s3_bucket_notification" "log_processor_bucket_notification" {
  bucket = var.bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.log_processor_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.bucket_path
  }
}

resource "aws_lambda_permission" "allow_s3_trigger" {
  statement_id  = "AllowExecutionByS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.log_processor_lambda.arn
  principal     = "s3.amazonaws.com"
  // source_arn    = 
}

