module "kms_logging" {
  source = "github.com/18F/identity-terraform//kms_log?ref=a383cf2dc02036029e966e3401fbbe07e77f7186"

  #source = "../../identity-terraform/kms_log"

  env_name                   = var.env_name
  kmslogging_service_enabled = var.kmslogging_enabled
  sns_topic_dead_letter_arn  = var.slack_events_sns_hook_arn
}

