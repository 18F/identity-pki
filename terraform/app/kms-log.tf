locals {
  kms_arns = concat([aws_iam_role.idp.arn, aws_iam_role.worker.arn], var.db_restore_role_arns)
}

module "kms_logging" {

  source = "github.com/18F/identity-terraform//kms_log?ref=77212f13fea5399bbe91c673f0e27cadd77e66b6"
  #source = "../../../identity-terraform/kms_log"

  env_name                                = var.env_name
  sns_topic_dead_letter_arn               = var.slack_events_sns_hook_arn
  kinesis_shard_count                     = var.kms_log_kinesis_shards
  ec2_kms_arns                            = local.kms_arns
  alarm_sns_topic_arns                    = var.kms_log_alerts_enabled ? [var.slack_events_sns_hook_arn] : []
  kinesis_retention_hours                 = var.kms_log_kinesis_retention_hours
  ct_queue_message_retention_seconds      = var.kms_log_ct_queue_message_retention_seconds
  dynamodb_retention_days                 = var.kms_log_dynamodb_retention_days
  kmslog_lambda_debug                     = var.kms_log_kmslog_lambda_debug
  lambda_identity_lambda_functions_gitrev = var.kms_log_lambda_identity_lambda_functions_gitrev
}

module "kms_keymaker_uw2" {
  source = "github.com/18F/identity-terraform//kms_keymaker?ref=bae596ff81e9617f480acad64a31740c573cc9ba"
  #source = "../../../identity-terraform/kms_keymaker"

  env_name      = var.env_name
  ec2_kms_arns  = local.kms_arns
  sqs_queue_arn = module.kms_logging.kms-ct-events-queue
}

module "kms_keymaker_ue1" {
  source = "github.com/18F/identity-terraform//kms_keymaker?ref=bae596ff81e9617f480acad64a31740c573cc9ba"
  #source = "../../../identity-terraform/kms_keymaker"
  providers = {
    aws = aws.use1
  }

  env_name      = var.env_name
  ec2_kms_arns  = local.kms_arns
  sqs_queue_arn = module.kms_logging.kms-ct-events-queue
}
