module "kms_logging" {
  source = "github.com/18F/identity-terraform//kms_log?ref=623dcf5201d2909c43f21f5bf80e72aa345cfe18"

  #source = "../../identity-terraform/kms_log"

  env_name                   = var.env_name
  kmslogging_service_enabled = var.kmslogging_enabled
  sns_topic_dead_letter_arn  = var.slack_events_sns_hook_arn
}

