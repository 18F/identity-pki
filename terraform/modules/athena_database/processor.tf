module "lambda_code" {
  count  = var.process_logs ? 1 : 0
  source = "github.com/18F/identity-terraform//null_archive?ref=e7ad5ef38f724b31911248a74173e9fee3bbf045"

  source_code_filename = "${var.log_processor_lambda}.py"
  source_dir           = "${path.module}/src/"
  zip_filename         = "${var.log_processor_lambda}.zip"
}

resource "aws_lambda_function" "log_processor_lambda" {
  count            = var.process_logs ? 1 : 0
  filename         = module.lambda_code[0].zip_output_path
  function_name    = "${var.env_name}-${var.lambda_name}"
  description      = var.lambda_description
  role             = aws_iam_role.cloudwatch_log_processor_lambda[0].arn
  handler          = "${var.log_processor_lambda}.lambda_handler"
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory
  source_code_hash = module.lambda_code[0].zip_output_base64sha256
  publish          = false

  ephemeral_storage {
    size = var.lambda_ephemeral_storage
  }

  depends_on = [module.lambda_code[0].resource_check]
}

resource "aws_s3_bucket_notification" "log_processor" {
  count  = var.process_logs ? 1 : 0
  bucket = var.bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.log_processor_lambda[0].arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.bucket_path
  }

  depends_on = [aws_lambda_permission.allow_s3_trigger]
}

resource "aws_lambda_permission" "allow_s3_trigger" {
  count         = var.process_logs ? 1 : 0
  statement_id  = "AllowExecutionByS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.log_processor_lambda[0].arn
  principal     = "s3.amazonaws.com"
  source_arn    = var.source_arn
}

