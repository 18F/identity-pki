module "log-ship-s3-soc" {
  source                                = "../modules/log_ship_s3_soc"
  region                                = "us-west-2"
  send_logs_to_s3                       = var.send_logs_to_s3
  kinesis_firehose_stream_name          = "cw-kinesis-s3-${var.env_name}-${var.region}"
  kinesis_firehose_stream_backup_prefix = "backup/"
  bucket_name                           = "login-gov-log-cache-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
  cloudwatch_subscription_filter_name   = "log-ship"
  cloudwatch_log_group_name             = var.cloudwatch_log_group_name
  cloudwatch_log_group_name_to_s3       = var.cloudwatch_log_group_name_to_s3
  env_name                              = var.env_name
  soc_destination_arn                   = var.soc_destination_arn
}
