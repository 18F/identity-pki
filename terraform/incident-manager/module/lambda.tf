module "lambda_insights" {
  source = "github.com/18F/identity-terraform//lambda_insights?ref=5c1a8fb0ca08aa5fa01a754a40ceab6c8075d4c9"
  #source = "../../../../identity-terraform/lambda_insights"

  region = var.region
}

resource "aws_cloudwatch_log_group" "incident_manager_actions" {
  for_each          = local.teams
  name              = "/aws/lambda/${each.key}-incident-manager-actions"
  retention_in_days = var.cloudwatch_retention_days
  skip_destroy      = false
}

module "incident_manager_actions_code" {
  source = "github.com/18F/identity-terraform//null_archive?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/null_archive"

  source_code_filename = "incident_manager_actions.py"
  source_dir           = "${path.module}/src/"
  zip_filename         = "incident_manager_actions_code.zip"
}

resource "aws_lambda_function" "incident_manager_actions_lambda" {
  for_each      = local.teams
  filename      = module.incident_manager_actions_code.zip_output_path
  function_name = "${each.key}-incident-manager-actions"
  role          = aws_iam_role.incident_manager_actions_lambda_role.arn
  description   = "Incident Manager-  Start Incident Trigger Function"
  handler       = "incident_manager_actions.lambda_handler"

  source_code_hash = module.incident_manager_actions_code.zip_output_base64sha256
  memory_size      = "3008"
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout

  environment {
    variables = {
      RESPONSE_PLAN_TEAM = title(each.key)
      RESPONSE_PLAN_ARN  = aws_ssmincidents_response_plan.response_plan[each.key].arn
    }
  }

  layers = [
    module.lambda_insights.layer_arn
  ]
  depends_on = [
    module.incident_manager_actions_code.resource_check,
    aws_cloudwatch_log_group.incident_manager_actions
  ]
}

module "incident_manager_actions_lambda_alerts" {
  for_each = local.teams
  source   = "github.com/18F/identity-terraform//lambda_alerts?ref=b4c39660e888c87e56fb910cca3104bd6a12b093"
  #source = "../../../../identity-terraform/lambda_alerts"

  function_name      = aws_lambda_function.incident_manager_actions_lambda[each.key].function_name
  alarm_actions      = [var.slack_notification_arn]
  insights_enabled   = true
  duration_setting   = aws_lambda_function.incident_manager_actions_lambda[each.key].timeout
  treat_missing_data = "notBreaching"
}

resource "aws_lambda_permission" "allow_eventbridge_to_invoke_lambda" {
  for_each      = local.teams
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.incident_manager_actions_lambda[each.key].function_name
  principal     = "events.amazonaws.com"
  source_arn    = "arn:aws:events:${var.region}:${data.aws_caller_identity.current.account_id}:rule/aws.partner/newrelic.com/*/${each.key}-*/new-relic-incident-manager-${each.key}-*"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_invoke_lambda" {
  for_each      = local.teams
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.incident_manager_actions_lambda[each.key].function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:${var.region}:${data.aws_caller_identity.current.account_id}:alarm:*"
}

resource "aws_cloudwatch_log_group" "incident_manager_shift" {
  name              = "/aws/lambda/incident-manager-shift"
  retention_in_days = var.cloudwatch_retention_days
  skip_destroy      = false
}

module "incident_manager_shift_code" {
  source = "github.com/18F/identity-terraform//null_archive?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/null_archive"

  source_code_filename = "incident_manager_shift.py"
  source_dir           = "${path.module}/src/"
  zip_filename         = "incident_manager_shift_code.zip"
}

resource "aws_lambda_function" "incident_manager_shift_lambda" {
  filename      = module.incident_manager_shift_code.zip_output_path
  function_name = "incident-manager-shift"
  role          = aws_iam_role.incident_manager_shift.arn
  description   = "Incident Manager-  Notify Incident Manager Shift Changes Function"
  handler       = "incident_manager_shift.lambda_handler"

  source_code_hash = module.incident_manager_shift_code.zip_output_base64sha256
  memory_size      = "256"
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout

  environment {
    variables = {
      SNS_CHANNEL = var.slack_notification_arn
    }
  }
  layers = [
    module.lambda_insights.layer_arn
  ]
  depends_on = [
    module.incident_manager_actions_code.resource_check,
    aws_cloudwatch_log_group.incident_manager_shift
  ]
}

module "incident_manager_shift_lambda_alerts" {
  source = "github.com/18F/identity-terraform//lambda_alerts?ref=b4c39660e888c87e56fb910cca3104bd6a12b093"
  #source = "../../../../identity-terraform/lambda_alerts"

  function_name      = aws_lambda_function.incident_manager_shift_lambda.function_name
  alarm_actions      = [var.slack_notification_arn]
  insights_enabled   = true
  duration_setting   = aws_lambda_function.incident_manager_shift_lambda.timeout
  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_event_rule" "trigger_schedule" {
  name                = "incident-manager-shift"
  description         = "Trigger AWS Lambda monitoring Incident Manager shift changes"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda" {
  rule = aws_cloudwatch_event_rule.trigger_schedule.name
  arn  = aws_lambda_function.incident_manager_shift_lambda.arn
}

resource "aws_lambda_permission" "allow_eventbridge_to_invoke_shift_lambda" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.incident_manager_shift_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.trigger_schedule.arn
}