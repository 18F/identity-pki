module "kms_logging" {
  source = "github.com/18F/identity-terraform//kms_log?ref=1db3ba569822d7803f2f6701fab5bc3242e2bb36"

  #source = "../../identity-terraform/kms_log"

  env_name                   = var.env_name
  kmslogging_service_enabled = var.kmslogging_enabled
  sns_topic_dead_letter_arn  = var.slack_events_sns_hook_arn
}

