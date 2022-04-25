data "archive_file" "config_access_key_rotation_lambda_function" {
  type        = "zip"
  source_file = "${path.module}/src/lambda_function.py"
  output_path = "${path.module}/${var.config_access_key_rotation_code}"
}

data "aws_caller_identity" "current" {}

resource "aws_lambda_function" "config_access_key_rotation_lambda" {
  filename      = data.archive_file.config_access_key_rotation_lambda_function.output_path
  function_name = "${var.config_access_key_rotation_name}-function"
  role          = aws_iam_role.config_access_key_rotation_lambda_role.arn
  description   = "IAM Access Key Rotation Function"
  handler       = "lambda_function.lambda_handler"

  source_code_hash = data.archive_file.config_access_key_rotation_lambda_function.output_base64sha256
  memory_size      = "3008"
  runtime          = "python3.9"
  timeout          = "300"

  environment {
    variables = {
      RotationPeriod  = 90,
      InactivePeriod  = 95,
      RetentionPeriod = 100
    }
  }
}

#resource "aws_lambda_permission" "config_access_key_rotation_lambda_permission" {
#  statement_id  = "${var.config_access_key_rotation_name}-lambda-permission"
#  function_name = aws_lambda_function.config_access_key_rotation_lambda.function_name
#  action        = "lambda:InvokeFunction"
#  principal     = "sns.amazonaws.com"
#  source_arn    = data.aws_sns_topic.config_access_key_rotation_topic.arn
#}