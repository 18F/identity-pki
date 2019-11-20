module "kms_logging" {
  source = "github.com/18F/identity-terraform//kms_log?ref=e5857113c460c7c085b88c8948b28798d6f17935"

  #source = "../../identity-terraform/kms_log"

  env_name                   = var.env_name
  kmslogging_service_enabled = var.kmslogging_enabled
  sns_topic_dead_letter_arn  = var.slack_events_sns_hook_arn
}

