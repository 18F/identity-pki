module "start_dms_task_code" {

  source = "github.com/18F/identity-terraform//null_archive?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  # source = "../../../../identity-terraform/null_archive"
  source_code_filename = "start_dms_task.py"
  source_dir           = "${path.module}/lambda/start_dms_task/"
  zip_filename         = "${path.module}/lambda/start_dms_task.zip"

}

resource "aws_lambda_function" "start_dms_task" {

  filename         = module.start_dms_task_code.zip_output_path
  source_code_hash = module.start_dms_task_code.zip_output_base64sha256
  function_name    = local.start_dms_task_lambda_name
  description      = "Starts Full-Load DMS task operations at specified time"
  role             = aws_iam_role.start_dms_task.arn
  handler          = "start_dms_task.lambda_handler"
  runtime          = "python3.9"
  timeout          = 120

  layers = [
    local.lambda_insights
  ]

  tags = {
    environment = var.env_name
  }

  environment {
    variables = {
      DMS_TASK_ARN  = aws_dms_replication_task.filtercolumns.replication_task_arn
      DMS_TASK_TYPE = aws_dms_replication_task.filtercolumns.migration_type
    }
  }

}

resource "aws_iam_role" "start_dms_task" {

  name               = "${local.start_dms_task_lambda_name}-execution"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
}

resource "aws_iam_role_policy" "start_tasks" {

  role   = aws_iam_role.start_dms_task.id
  policy = data.aws_iam_policy_document.start_dms_task_policies.json
}

data "aws_iam_policy_document" "start_dms_task_policies" {

  statement {
    sid    = "AllowStartReplicationTasks"
    effect = "Allow"
    actions = [
      "dms:StartReplicationTask",
    ]

    resources = [
      aws_dms_replication_task.filtercolumns.replication_task_arn
    ]
  }
  statement {
    sid    = "AllowDescribeReplicationTasks"
    effect = "Allow"
    actions = [
      "dms:DescribeReplicationTasks"
    ]

    resources = [
      "arn:aws:dms:${var.region}:${var.account_id}:*:*"
    ]
  }

  statement {
    sid    = "LogInvocationsToCloudwatch"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/lambda/${local.start_dms_task_lambda_name}:*"
    ]
  }
}

resource "aws_cloudwatch_event_rule" "start_dms_task_schedule" {

  name                = "${local.start_dms_task_lambda_name}-schedule"
  description         = "Daily Trigger for start_dms_task"
  schedule_expression = var.start_dms_task_lambda_schedule
}

resource "aws_cloudwatch_event_target" "start_dms_task" {

  rule = aws_cloudwatch_event_rule.start_dms_task_schedule.name
  arn  = aws_lambda_function.start_dms_task.arn
}

resource "aws_lambda_permission" "start_dms_task_allow_events_bridge_to_run_lambda" {

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_dms_task.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_dms_task_schedule.arn
}
