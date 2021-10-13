module "kinesis-firehose" {
  source                                = "../modules/aws-kinesis-firehose"
  region                                = "us-west-2"
  kinesis_firehose_stream_name          = "cw-kinesis-s3-${var.env_name}-${var.region}"
  kinesis_firehose_stream_backup_prefix = "backup/"
  bucket_name                           = "login-gov-idp-events-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
  cloudwatch_subscription_filter_name   = "cw-kinesis-s3-idp-events"
  cloudwatch_log_group_name             = ["${var.env_name}_/srv/idp/shared/log/events.log", "${var.env_name}_/srv/idp/shared/log/workers.log"]
  cloudwatch_filter_pattern             = " "
}


