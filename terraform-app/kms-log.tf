module "kms_logging" {
    source = "github.com/18F/identity-terraform//kms_log?ref=ce6978c2ebe1e0997a7f88d56fbdd05d1ea687d6"
    #source = "../../identity-terraform/kms_log"

    env_name = "${var.env_name}"
    kmslogging_service_enabled = "${var.kmslogging_enabled}"
    sns_topic_dead_letter_arn = "${var.slack_events_sns_hook_arn}"
}
