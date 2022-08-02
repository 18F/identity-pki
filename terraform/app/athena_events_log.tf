locals{
  events_log_bucket_name   = "login-gov-log-cache-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
}

data "aws_iam_policy_document" "cloudwatch_process_logs" {
  statement {
    sid    = "AllowProcessCloudWatchLogs"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::${local.events_log_bucket_name}",
      "arn:aws:s3:::${local.events_log_bucket_name}/*"
    ]
  }
}

resource "aws_iam_role_policy" "cloudwatch_process_logs" {
  name   = "${var.env_name}-cloudwatch-process-logs"
  role   = module.cloudwatch_events_log_processors.cloudwatch_log_processor_lambda_iam_role.id
  policy = data.aws_iam_policy_document.cloudwatch_process_logs.json
}

module "cloudwatch_events_log_processors"{
  source        = "../modules/cloudwatch_log_processors"
  kms_resources =  [module.kinesis-firehose.kinesis_firehose_stream_bucket]

  env_name      = var.env_name
  region        = var.region
  bucket_name   = local.events_log_bucket_name
}

