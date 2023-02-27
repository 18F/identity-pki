module "config_access_key_rotation_code" {
  source = "github.com/18F/identity-terraform//null_archive?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/null_archive"

  source_code_filename = "config_access_key_rotation.py"
  source_dir           = "${path.module}/src/"
  zip_filename         = var.config_access_key_rotation_code
}

data "aws_caller_identity" "current" {}

resource "aws_lambda_function" "config_access_key_rotation_lambda" {
  filename      = module.config_access_key_rotation_code.zip_output_path
  function_name = "${var.config_access_key_rotation_name}-function"
  role          = aws_iam_role.config_access_key_rotation_lambda_role.arn
  description   = "IAM Access Key Rotation Function"
  handler       = "config_access_key_rotation.lambda_handler"

  source_code_hash = module.config_access_key_rotation_code.zip_output_base64sha256
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

  depends_on = [module.config_access_key_rotation_code.resource_check]
}

#resource "aws_lambda_permission" "config_access_key_rotation_lambda_permission" {
#  statement_id  = "${var.config_access_key_rotation_name}-lambda-permission"
#  function_name = aws_lambda_function.config_access_key_rotation_lambda.function_name
#  action        = "lambda:InvokeFunction"
#  principal     = "sns.amazonaws.com"
#  source_arn    = "arn:aws:sns:${var.region}:${data.aws_caller_identity.current.account_id}:${var.slack_events_sns_topic}"
#}