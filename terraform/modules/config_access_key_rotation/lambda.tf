resource "aws_lambda_function" "config_access_key_rotation_lambda" {
  filename      = "${path.module}/${var.config_access_key_rotation_code}"
  function_name = "${var.config_access_key_rotation_name}-function"
  role          = aws_iam_role.config_access_key_rotation_lambda_role.arn
  description   = "IAM Access Key Rotation Function"
  handler       = "lambda_function.lambda_handler"

  source_code_hash = filebase64sha256("${path.module}/${var.config_access_key_rotation_code}")
  memory_size      = "3008"
  runtime          = "python3.8"
  timeout          = "300"

  environment {
    variables = {
      RotationPeriod  = 90,
      InactivePeriod  = 95,
      RetentionPeriod = 100
    }
  }
}

resource "aws_lambda_permission" "config_access_key_rotation_lambda_permission" {
  statement_id  = "${var.config_access_key_rotation_name}-lambda-permission"
  function_name = aws_lambda_function.config_access_key_rotation_lambda.function_name
  action        = "lambda:InvokeFunction"
  principal     = "sns.amazonaws.com"
  source_arn    = "${data.aws_sns_topic.config_access_key_rotation_topic.arn}"
}