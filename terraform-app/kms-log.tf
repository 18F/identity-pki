module "kms_logging" {
  source = "github.com/18F/identity-terraform//kms_log?ref=a58d0581b04b3562885dca32e07c0751e794db88"

  #source = "../../identity-terraform/kms_log"

  env_name                   = var.env_name
  kmslogging_service_enabled = var.kmslogging_enabled
  sns_topic_dead_letter_arn  = var.slack_events_sns_hook_arn
  kinesis_shard_count        = var.kms_log_kinesis_shards
  ec2_kms_arns               = concat([aws_iam_role.idp.arn],var.db_restore_role_arns)
}

