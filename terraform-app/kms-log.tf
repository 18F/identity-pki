module "kms_logging" {
  source = "github.com/18F/identity-terraform//kms_log?ref=379b9ca062233ddf26b69c021b7a8546532ec934"

  #source = "../../identity-terraform/kms_log"

  env_name                   = var.env_name
  kmslogging_service_enabled = var.kmslogging_enabled
  sns_topic_dead_letter_arn  = var.slack_events_sns_hook_arn
}

