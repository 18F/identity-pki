module "config_access_key_rotation_code" {
  source = "github.com/18F/identity-terraform//null_archive?ref=9ca808e1cad7add8e7bdccd6aa1199d873d34d54"

  source_code_filename = "config_access_key_rotation.py"
  source_dir           = "${path.module}/src/"
  zip_filename         = var.config_access_key_rotation_code
}

resource "aws_lambda_function" "config_access_key_rotation_lambda" {
  filename      = module.config_access_key_rotation_code.zip_output_path
  function_name = "${var.config_access_key_rotation_name}-function"
  role          = aws_iam_role.config_access_key_rotation_lambda_role.arn
  description   = "IAM Access Key Rotation Function"
  handler       = "config_access_key_rotation.lambda_handler"

  source_code_hash = module.config_access_key_rotation_code.zip_output_base64sha256
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
  source_arn    = data.aws_sns_topic.config_access_key_rotation_topic.arn
}