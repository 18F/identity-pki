data "aws_ip_ranges" "s3_cidr_blocks" {
  regions  = [var.region]
  services = ["s3"]
}

data "aws_iam_policy_document" "assume_role_lambda" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

locals {
  analytics_import_bucket = join("-", [
    "login-gov-redshift-import-${var.env_name}",
    "${var.analytics_account_id}-${var.region}"
  ])

  analytics_import_arn             = "arn:aws:s3:::${local.analytics_import_bucket}"
  transform_cw_export_lambda_name  = "${var.env_name}-transform-cw-export"
  start_dms_task_lambda_name       = "${var.env_name}-start-dms-task"
  start_cw_export_task_lambda_name = "${var.env_name}-start-cw-export"

  lambda_insights = "arn:aws:lambda:${var.region}:${var.lambda_insights_account}:layer:LambdaInsightsExtension:${var.lambda_insights_version}"

  analytics_target_log_groups = [
    {
      resource     = aws_cloudwatch_log_group.log["idp_production"],
      json_encoded = "true"
    },
    {
      resource     = aws_cloudwatch_log_group.log["idp_events"],
      json_encoded = "true"
    }
  ]
}

resource "aws_network_acl_rule" "db-ingress-s3-ephemeral" {
  for_each       = var.enable_dms_analytics ? toset(data.aws_ip_ranges.s3_cidr_blocks.cidr_blocks) : []
  network_acl_id = module.network_uw2.db_nacl_id
  egress         = false
  from_port      = 32768
  to_port        = 61000
  protocol       = "tcp"
  rule_number    = index(data.aws_ip_ranges.s3_cidr_blocks.cidr_blocks, each.value) + 20
  rule_action    = "allow"
  cidr_block     = each.value
}

resource "aws_network_acl_rule" "db-egress-s3-https" {
  for_each       = var.enable_dms_analytics ? toset(data.aws_ip_ranges.s3_cidr_blocks.cidr_blocks) : []
  network_acl_id = module.network_uw2.db_nacl_id
  egress         = true
  from_port      = 443
  to_port        = 443
  protocol       = "tcp"
  rule_number    = index(data.aws_ip_ranges.s3_cidr_blocks.cidr_blocks, each.value) + 20
  rule_action    = "allow"
  cidr_block     = each.value
}

resource "aws_s3_bucket" "analytics_export" {
  count = var.enable_dms_analytics ? 1 : 0
  bucket = join("-", [
    "login-gov-analytics-export-${var.env_name}",
    "${data.aws_caller_identity.current.account_id}-${var.region}"
  ])
}

module "analytics_export_bucket_config" {
  count  = var.enable_dms_analytics ? 1 : 0
  source = "github.com/18F/identity-terraform//s3_config?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/s3_config"
  depends_on = [aws_s3_bucket.analytics_export]

  bucket_name_override = aws_s3_bucket.analytics_export[count.index].id
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_arn
}

resource "aws_s3_bucket_versioning" "analytics_export" {
  count  = var.enable_dms_analytics ? 1 : 0
  bucket = aws_s3_bucket.analytics_export[count.index].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "analytics_export" {
  count  = var.enable_dms_analytics ? 1 : 0
  bucket = aws_s3_bucket.analytics_export[count.index].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_notification" "trigger_transform" {
  bucket = aws_s3_bucket.analytics_export[count.index].id
  count  = var.enable_dms_analytics ? 1 : 0
  lambda_function {
    lambda_function_arn = aws_lambda_function.transform_cw_export[count.index].arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "logs/"
    filter_suffix       = ".gz"
  }
}

resource "aws_s3_bucket_policy" "analytics_export_allow_export_tasks" {
  count  = var.enable_dms_analytics ? 1 : 0
  bucket = aws_s3_bucket.analytics_export[count.index].id
  policy = data.aws_iam_policy_document.allow_export_tasks[count.index].json
}

data "aws_iam_policy_document" "allow_export_tasks" {
  count = var.enable_dms_analytics ? 1 : 0
  statement {
    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }
    effect = "Allow"
    actions = [
      "s3:GetBucketAcl"
    ]
    resources = [
      aws_s3_bucket.analytics_export[count.index].arn
    ]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"

      values = [for log_group in local.analytics_target_log_groups : "${log_group.resource.arn}:*"]
    }
  }
  statement {
    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.analytics_export[count.index].arn}/*"
    ]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"

      values = [for log_group in local.analytics_target_log_groups : "${log_group.resource.arn}:*"]
    }
  }

  statement {
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:*",
    ]
    resources = [
      "${aws_s3_bucket.analytics_export[count.index].arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_acl" "analytics_export" {
  count  = var.enable_dms_analytics ? 1 : 0
  bucket = aws_s3_bucket.analytics_export[count.index].id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.analytics_export]
}

resource "aws_s3_bucket_public_access_block" "analytics_export" {
  count  = var.enable_dms_analytics ? 1 : 0
  bucket = aws_s3_bucket.analytics_export[count.index].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "analytics_export" {
  count  = var.enable_dms_analytics ? 1 : 0
  bucket = aws_s3_bucket.analytics_export[count.index].bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_replication_configuration" "to_analytics" {
  count  = var.enable_dms_analytics ? 1 : 0
  role   = aws_iam_role.replication[count.index].arn
  bucket = aws_s3_bucket.analytics_export[count.index].id

  depends_on = [
    aws_s3_bucket_versioning.analytics_export
  ]

  rule {
    id     = "ToAnalyticsAccount"
    status = "Enabled"
    filter {}

    destination {

      bucket  = local.analytics_import_arn
      account = var.analytics_account_id

      access_control_translation {
        owner = "Destination"
      }

      metrics {
        status = "Enabled"
      }
    }

    delete_marker_replication {
      status = "Enabled"
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "s3_replication_failed_operations_analytics" {
  count               = var.enable_dms_analytics ? 1 : 0
  alarm_name          = "${var.env_name}-idp-s3-toAnalyticsAccount-replicationFailed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "OperationsFailedReplication"
  namespace           = "AWS/S3"
  period              = 3600
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_description   = <<EOM
The S3 replication failed for the "login-gov-analytics-export" bucket.

Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Data-Warehouse-Alerts-Troubleshooting#s3-replication-alerts
EOM

  dimensions = {
    BucketName  = aws_s3_bucket.analytics_export[count.index].id
    StorageType = "AllStorageTypes"
  }

  alarm_actions = local.low_priority_dw_alarm_actions
  ok_actions    = local.low_priority_dw_alarm_actions

  actions_enabled = true
}

data "aws_iam_policy_document" "replication" {
  count = var.enable_dms_analytics ? 1 : 0
  statement {
    effect = "Allow"

    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]

    resources = [aws_s3_bucket.analytics_export[count.index].arn]
  }
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]

    resources = ["${aws_s3_bucket.analytics_export[count.index].arn}/*"]
  }
  statement {
    effect = "Allow"

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:PutObject",
      "s3:ObjectOwnerOverrideToBucketOwner",
    ]

    resources = ["${local.analytics_import_arn}/*"]
  }
}

resource "aws_iam_policy" "replication" {
  count  = var.enable_dms_analytics ? 1 : 0
  name   = "login-gov-${var.env_name}-analytics-replication-policy"
  policy = data.aws_iam_policy_document.replication[count.index].json
}

resource "aws_iam_role_policy_attachment" "replication" {
  count      = var.enable_dms_analytics ? 1 : 0
  role       = aws_iam_role.replication[count.index].name
  policy_arn = aws_iam_policy.replication[count.index].arn
}

data "aws_iam_policy_document" "s3_assume_role" {
  count = var.enable_dms_analytics ? 1 : 0
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "replication" {
  count              = var.enable_dms_analytics ? 1 : 0
  name               = "login-gov-${var.env_name}-analytics-replication"
  assume_role_policy = data.aws_iam_policy_document.s3_assume_role[count.index].json
}


data "aws_iam_policy_document" "dms_s3" {
  count = var.enable_dms_analytics ? 1 : 0

  statement {
    sid    = "AllowWriteToS3"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObjectTagging",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketAcl"
    ]
    resources = [
      aws_s3_bucket.analytics_export[count.index].arn,
      "${aws_s3_bucket.analytics_export[count.index].arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "dms_s3" {
  count = var.enable_dms_analytics ? 1 : 0

  name   = "${var.env_name}-dms-s3"
  role   = module.dms[0].dms_role.name
  policy = data.aws_iam_policy_document.dms_s3[count.index].json
}

resource "aws_dms_s3_endpoint" "analytics_export" {
  count = var.enable_dms_analytics ? 1 : 0

  endpoint_id             = "${var.env_name}-analytics-export"
  endpoint_type           = "target"
  bucket_name             = aws_s3_bucket.analytics_export[count.index].id
  service_access_role_arn = module.dms[0].dms_role.arn
  add_column_name         = true

  depends_on = [aws_iam_role_policy.dms_s3]
}

resource "aws_iam_role" "start_cw_export_task" {
  count              = var.enable_dms_analytics ? 1 : 0
  name               = "${local.start_cw_export_task_lambda_name}-execution"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
}

resource "aws_iam_role_policy" "start_cw_export_task" {
  count  = var.enable_dms_analytics ? 1 : 0
  role   = aws_iam_role.start_cw_export_task[count.index].id
  policy = data.aws_iam_policy_document.start_cw_export_task[count.index].json

  depends_on = [aws_lambda_function.start_cw_export_task]
}

data "aws_iam_policy_document" "start_cw_export_task" {
  count = var.enable_dms_analytics ? 1 : 0
  statement {
    sid    = "AllowCloudWatchLogsExportTasks"
    effect = "Allow"
    actions = [
      "logs:CreateExportTask",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
    ]

    resources = [for log_group in local.analytics_target_log_groups : "${log_group.resource.arn}:log-stream:"]
  }
  statement {
    sid    = "DescribeExportTasks"
    effect = "Allow"
    actions = [
      "logs:DescribeExportTasks",
    ]

    resources = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group::log-stream:"]
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
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.start_cw_export_task_lambda_name}:*"
    ]
  }
}

module "start_cw_export_task_code" {
  count  = var.enable_dms_analytics ? 1 : 0
  source = "github.com/18F/identity-terraform//null_archive?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  # source = "../../../../identity-terraform/null_archive"
  source_code_filename = "start_cw_export_task.py"
  source_dir           = "${path.module}/lambda/start_cw_export_task/"
  zip_filename         = "${path.module}/lambda/start_cw_export_task.zip"

}

resource "aws_lambda_function" "start_cw_export_task" {
  count            = var.enable_dms_analytics ? 1 : 0
  filename         = module.start_cw_export_task_code[count.index].zip_output_path
  source_code_hash = module.start_cw_export_task_code[count.index].zip_output_base64sha256
  function_name    = local.start_cw_export_task_lambda_name
  description      = "Exports Cloudwatch Logs to dedicated s3 bucket for replication to analytics account"
  role             = aws_iam_role.start_cw_export_task[count.index].arn
  handler          = "start_cw_export_task.lambda_handler"
  runtime          = "python3.9"
  timeout          = 900 # in seconds, 15 minutes

  layers = [
    local.lambda_insights
  ]

  tags = {
    environment = var.env_name
  }

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.analytics_export[count.index].id
      LOG_GROUPS = jsonencode([
        for log_group in local.analytics_target_log_groups : { name = log_group.resource.name, json_encoded = log_group.json_encoded }
      ])
      PREVIOUS_DAYS = 1
    }
  }

}

resource "aws_lambda_permission" "transform_cw_export_s3_events" {
  count         = var.enable_dms_analytics ? 1 : 0
  action        = "lambda:InvokeFunction"
  statement_id  = "AllowInvokeFromS3"
  function_name = aws_lambda_function.transform_cw_export[count.index].function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.analytics_export[count.index].arn
}

module "transform_cw_export_code" {
  count  = var.enable_dms_analytics ? 1 : 0
  source = "github.com/18F/identity-terraform//null_archive?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  # source = "../../../../identity-terraform/null_archive"
  source_code_filename = "transform_cw_export.py"
  source_dir           = "${path.module}/lambda/transform_cw_export/"
  zip_filename         = "${path.module}/lambda/transform_cw_export.zip"

}

resource "aws_lambda_function" "transform_cw_export" {
  count            = var.enable_dms_analytics ? 1 : 0
  filename         = module.transform_cw_export_code[count.index].zip_output_path
  source_code_hash = module.transform_cw_export_code[count.index].zip_output_base64sha256
  function_name    = local.transform_cw_export_lambda_name
  description      = "Transforms Cloudwatch Exports to CSV for consumption in analytics account"
  role             = aws_iam_role.transform_cw_export[count.index].arn
  handler          = "transform_cw_export.lambda_handler"
  runtime          = "python3.9"
  memory_size      = var.transform_cw_export_memory_size
  timeout          = 900 # in seconds, 15 minutes

  layers = [
    local.lambda_insights
  ]

  tags = {
    environment = var.env_name
  }

  environment {
    variables = {
      LOG_GROUPS = jsonencode([
        for log_group in local.analytics_target_log_groups : { name = log_group.resource.name, json_encoded = log_group.json_encoded }
      ])
    }
  }

}

resource "aws_iam_role" "transform_cw_export" {
  count              = var.enable_dms_analytics ? 1 : 0
  name               = "${local.transform_cw_export_lambda_name}-execution"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
}

resource "aws_iam_role_policy" "transform" {
  count  = var.enable_dms_analytics ? 1 : 0
  role   = aws_iam_role.transform_cw_export[count.index].id
  policy = data.aws_iam_policy_document.transform_cw_export[count.index].json
}

data "aws_iam_policy_document" "transform_cw_export" {
  count = var.enable_dms_analytics ? 1 : 0
  statement {
    sid    = "TransformationPermissions"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:ListObjectsv2",
    ]

    resources = [
      aws_s3_bucket.analytics_export[count.index].arn,
      "${aws_s3_bucket.analytics_export[count.index].arn}/*"
    ]
  }
  statement {
    sid    = "GetLogStreamData"
    effect = "Allow"
    actions = [
      "logs:DescribeLogStreams",
    ]
    resources = [
      for log_group in local.analytics_target_log_groups : "${log_group.resource.arn}:log-stream:"
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
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.transform_cw_export_lambda_name}:*"
    ]
  }
}

resource "aws_cloudwatch_event_rule" "start_cw_export_task_schedule" {
  count               = var.enable_dms_analytics ? 1 : 0
  name                = "${local.start_cw_export_task_lambda_name}-schedule"
  description         = "Daily Trigger for start-cw-export-task"
  schedule_expression = var.start_cw_export_task_lambda_schedule
}

resource "aws_cloudwatch_event_target" "start_cw_export_task" {
  count = var.enable_dms_analytics ? 1 : 0
  rule  = aws_cloudwatch_event_rule.start_cw_export_task_schedule[count.index].name
  arn   = aws_lambda_function.start_cw_export_task[count.index].arn
}

resource "aws_lambda_permission" "allow_events_bridge_to_run_lambda" {
  count         = var.enable_dms_analytics ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_cw_export_task[count.index].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_cw_export_task_schedule[count.index].arn
}

module "start_dms_task_code" {
  count  = var.enable_dms_analytics ? 1 : 0
  source = "github.com/18F/identity-terraform//null_archive?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  # source = "../../../../identity-terraform/null_archive"
  source_code_filename = "start_dms_task.py"
  source_dir           = "${path.module}/lambda/start_dms_task/"
  zip_filename         = "${path.module}/lambda/start_dms_task.zip"

}

resource "aws_lambda_function" "start_dms_task" {
  count            = var.enable_dms_analytics ? 1 : 0
  filename         = module.start_dms_task_code[count.index].zip_output_path
  source_code_hash = module.start_dms_task_code[count.index].zip_output_base64sha256
  function_name    = local.start_dms_task_lambda_name
  description      = "Starts Full-Load DMS task operations at specified time"
  role             = aws_iam_role.start_dms_task[count.index].arn
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
      DMS_TASK_ARN  = aws_dms_replication_task.filtercolumns[count.index].replication_task_arn
      DMS_TASK_TYPE = aws_dms_replication_task.filtercolumns[count.index].migration_type
    }
  }

}

resource "aws_iam_role" "start_dms_task" {
  count              = var.enable_dms_analytics ? 1 : 0
  name               = "${local.start_dms_task_lambda_name}-execution"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
}

resource "aws_iam_role_policy" "start_tasks" {
  count  = var.enable_dms_analytics ? 1 : 0
  role   = aws_iam_role.start_dms_task[count.index].id
  policy = data.aws_iam_policy_document.start_dms_task_policies[count.index].json
}

data "aws_iam_policy_document" "start_dms_task_policies" {
  count = var.enable_dms_analytics ? 1 : 0
  statement {
    sid    = "AllowStartReplicationTasks"
    effect = "Allow"
    actions = [
      "dms:StartReplicationTask",
    ]

    resources = [
      aws_dms_replication_task.filtercolumns[count.index].replication_task_arn
    ]
  }
  statement {
    sid    = "AllowDescribeReplicationTasks"
    effect = "Allow"
    actions = [
      "dms:DescribeReplicationTasks"
    ]

    resources = [
      "arn:aws:dms:${var.region}:${data.aws_caller_identity.current.account_id}:*:*"
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
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.start_dms_task_lambda_name}:*"
    ]
  }
}

resource "aws_cloudwatch_event_rule" "start_dms_task_schedule" {
  count               = var.enable_dms_analytics ? 1 : 0
  name                = "${local.start_dms_task_lambda_name}-schedule"
  description         = "Daily Trigger for start_dms_task"
  schedule_expression = var.start_dms_task_lambda_schedule
}

resource "aws_cloudwatch_event_target" "start_dms_task" {
  count = var.enable_dms_analytics ? 1 : 0
  rule  = aws_cloudwatch_event_rule.start_dms_task_schedule[count.index].name
  arn   = aws_lambda_function.start_dms_task[count.index].arn
}

resource "aws_lambda_permission" "start_dms_task_allow_events_bridge_to_run_lambda" {
  count         = var.enable_dms_analytics ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_dms_task[count.index].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_dms_task_schedule[count.index].arn
}
