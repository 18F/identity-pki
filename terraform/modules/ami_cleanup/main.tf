resource "aws_cloudwatch_log_group" "ami_cleanup_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.ami_cleanup.function_name}"
  retention_in_days = 30
}

module "ami_cleanup_function_code" {
  source = "github.com/18F/identity-terraform//null_archive?ref=0fe0243d7df353014c757a72ef0c48f5805fb3d3"

  source_code_filename = "ami_cleanup.py"
  source_dir           = "${path.module}/files/"

  zip_filename = "ami_cleanup.zip"
}

resource "aws_lambda_function" "ami_cleanup" {
  filename         = module.ami_cleanup_function_code.zip_output_path
  function_name    = "ami_cleanup"
  description      = "Lambda function to remove old or unused AMIs"
  role             = aws_iam_role.lambda_ami_cleanup.arn
  handler          = "ami_cleanup.lambda_handler"
  runtime          = "python3.9"
  timeout          = 300
  source_code_hash = module.ami_cleanup_function_code.zip_output_base64sha256
  publish          = false

  depends_on = [module.ami_cleanup_function_code.resource_check]
}

resource "aws_cloudwatch_event_rule" "Run_ami_cleanup" {
  name                = "Run-ami_cleanup"
  description         = "Fires every 8 hours"
  schedule_expression = "cron(0 8 ? * * *)"
}

resource "aws_cloudwatch_event_target" "target_ami_cleanup" {
  rule      = aws_cloudwatch_event_rule.Run_ami_cleanup.name
  target_id = aws_lambda_function.ami_cleanup.function_name
  arn       = aws_lambda_function.ami_cleanup.arn

  input = "{\"expireUnassociatedinDays\":\"${var.expire_unassociated_in_days}\",\"expireAssociatedinDays\": \"${var.expire_associated_in_days}\",\"dryRun\": \"True\" }"
}

resource "aws_lambda_permission" "cloudwatch_to_ami_cleanup" {
  statement_id  = "AWSEvents_Run-ami_cleanup_Id425665071155"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ami_cleanup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.Run_ami_cleanup.arn
}

