module "kms_logging" {
  source = "github.com/18F/identity-terraform//kms_log?ref=a02e8ecfd4c6e952ad6a8958158a4b455807fa2e"

  #source = "../../identity-terraform/kms_log"

  env_name                   = var.env_name
  kmslogging_service_enabled = var.kmslogging_enabled
  sns_topic_dead_letter_arn  = var.slack_events_sns_hook_arn
}

