module "kms_logging" {
  source = "github.com/18F/identity-terraform//kms_log?ref=d1402b5b98174e9a8aa23f1be05b2a8e39223fd4"

  #source = "../../identity-terraform/kms_log"

  env_name                   = var.env_name
  kmslogging_service_enabled = var.kmslogging_enabled
  sns_topic_dead_letter_arn  = var.slack_events_sns_hook_arn
}

