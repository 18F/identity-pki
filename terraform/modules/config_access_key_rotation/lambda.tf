module "lambda_insights" {
  source = "github.com/18F/identity-terraform//lambda_insights?ref=0cb56606de47507e5748ab55bfa51fa72424313f"
  #source = "../../../../identity-terraform/lambda_insights"
}

module "config_access_key_rotation_code" {
  source = "github.com/18F/identity-terraform//null_archive?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/null_archive"

  source_code_filename = "config_access_key_rotation.py"
  source_dir           = "${path.module}/src/"
  zip_filename         = "${path.module}/${var.config_access_key_rotation_code}"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.config_access_key_rotation_name}-function"
  retention_in_days = var.cloudwatch_retention_days
  skip_destroy      = true
}

moved {
  from = aws_lambda_function.config_access_key_rotation_lambda
  to   = aws_lambda_function.config_access_key_rotation
}

resource "aws_lambda_function" "config_access_key_rotation" {
  filename      = module.config_access_key_rotation_code.zip_output_path
  function_name = "${var.config_access_key_rotation_name}-function"
  role          = aws_iam_role.config_access_key_rotation.arn
  description   = "IAM Access Key Rotation Function"
  handler       = "config_access_key_rotation.lambda_handler"

  source_code_hash = module.config_access_key_rotation_code.zip_output_base64sha256
  memory_size      = "3008"
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout

  layers = [
    module.lambda_insights.layer_arn
  ]

  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.lambda.name
  }

  environment {
    variables = {
      RotationPeriod   = 80,
      InactivePeriod   = 90,
      RetentionPeriod  = 100,
      users_to_ignore  = "ses-smtp" #comma delimited list of IAM usernames to ignore
      lambda_temp_role = "${aws_iam_role.assumeRole_lambda.arn}"
    }
  }

  depends_on = [module.config_access_key_rotation_code.resource_check]
}

module "config_access_key_rotation_alerts" {
  source = "github.com/18F/identity-terraform//lambda_alerts?ref=0cb56606de47507e5748ab55bfa51fa72424313f"
  #source = "../../../../identity-terraform/lambda_alerts"

  function_name = aws_lambda_function.config_access_key_rotation.function_name
  alarm_actions = [for topic in data.aws_sns_topic.alarm_targets : topic.arn]

  datapoints_to_alarm  = 1
  error_rate_threshold = 1 # percent
  evaluation_periods   = 5
  treat_missing_data   = "ignore"

  insights_enabled = true
  duration_setting = aws_lambda_function.config_access_key_rotation.timeout
}
