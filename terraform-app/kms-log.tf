module "kms_logging" {
  source = "github.com/18F/identity-terraform//kms_log?ref=6d0c28e58bbf4d5d9840902abb1127aa1fa5767b"

  #source = "../../identity-terraform/kms_log"

  env_name                   = var.env_name
  kmslogging_service_enabled = var.kmslogging_enabled
  sns_topic_dead_letter_arn  = var.slack_events_sns_hook_arn
}

