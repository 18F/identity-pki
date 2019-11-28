module "kms_logging" {
  source = "github.com/18F/identity-terraform//kms_log?ref=beeed1e3d70ba34aaf9198810399843adebfca22"

  #source = "../../identity-terraform/kms_log"

  env_name                   = var.env_name
  kmslogging_service_enabled = var.kmslogging_enabled
  sns_topic_dead_letter_arn  = var.slack_events_sns_hook_arn
}

