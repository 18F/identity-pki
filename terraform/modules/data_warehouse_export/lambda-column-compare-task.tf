
module "column_compare_task" {

  source = "github.com/18F/identity-terraform//lambda_function?ref=e8f4003725ced00b0ff031c66f720cdfa49d6705"
  #source = "../../../../identity-terraform/lambda_function"

  # lambda function
  region               = var.region
  function_name        = "${var.env_name}-column-compare-task"
  description          = "Compare dms mapping rule json with idp sensitive column json"
  source_code_filename = "column_compare_task.py"
  source_dir           = "${path.module}/lambda/column_compare_task/"
  runtime              = "python3.12"

  environment_variables = {
    DMS_TASK_ARN = aws_dms_replication_task.filtercolumns.replication_task_arn
    S3_BUCKET    = aws_s3_bucket.idp_dw_tasks.id
  }

  # Logging and alarms
  cloudwatch_retention_days = var.cloudwatch_retention_days
  alarm_actions             = var.low_priority_dw_alarm_actions
  ok_actions                = var.low_priority_dw_alarm_actions
  treat_missing_data        = "notBreaching"

  # Lambda trigger (EventBridge event or schedule)
  # schedule_expression = "rate(1 day)"

  # IAM permissions
  lambda_iam_policy_document = data.aws_iam_policy_document.column_compare_task_policies.json
}





