module "start_cw_export_task_code" {

  source = "github.com/18F/identity-terraform//null_archive?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  # source = "../../../../identity-terraform/null_archive"
  source_code_filename = "start_cw_export_task.py"
  source_dir           = "${path.module}/lambda/start_cw_export_task/"
  zip_filename         = "${path.module}/lambda/start_cw_export_task.zip"

}

resource "aws_lambda_function" "start_cw_export_task" {

  filename         = module.start_cw_export_task_code.zip_output_path
  source_code_hash = module.start_cw_export_task_code.zip_output_base64sha256
  function_name    = local.start_cw_export_task_lambda_name
  description      = "Exports Cloudwatch Logs to dedicated s3 bucket for replication to analytics account"
  role             = aws_iam_role.start_cw_export_task.arn
  handler          = "start_cw_export_task.lambda_handler"
  runtime          = "python3.9"
  timeout          = var.data_warehouse_export_lambda_timeout # in seconds, 15 minutes

  layers = [
    local.lambda_insights
  ]

  tags = {
    environment = var.env_name
  }

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.analytics_export.id
      LOG_GROUPS = jsonencode([
        for log_group in local.analytics_target_log_groups : { name = log_group.resource.name, json_encoded = log_group.json_encoded }
      ])
      PREVIOUS_DAYS = 1
    }
  }

}

resource "aws_cloudwatch_event_rule" "start_cw_export_task_schedule" {

  name                = "${local.start_cw_export_task_lambda_name}-schedule"
  description         = "Daily Trigger for start-cw-export-task"
  schedule_expression = var.start_cw_export_task_lambda_schedule
}

resource "aws_cloudwatch_event_target" "start_cw_export_task" {

  rule = aws_cloudwatch_event_rule.start_cw_export_task_schedule.name
  arn  = aws_lambda_function.start_cw_export_task.arn
}

resource "aws_lambda_permission" "allow_events_bridge_to_run_lambda" {

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_cw_export_task.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_cw_export_task_schedule.arn
}

