module "kms_logging" {
  source = "github.com/18F/identity-terraform//kms_log?ref=19a1a7d7a5c3e2177f62d96a553fed53ac2c251c"

  #source = "../../identity-terraform/kms_log"

  env_name                   = var.env_name
  kmslogging_service_enabled = var.kmslogging_enabled
  sns_topic_dead_letter_arn  = var.slack_events_sns_hook_arn
  kinesis_shard_count        = var.kms_log_kinesis_shards
}

