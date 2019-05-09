module "kms_logging" {
    source = "github.com/18F/identity-terraform//kms_log?ref=125a02727194413fe00339f1262e79bfa1da0416"
    #source = "../../identity-terraform/kms_log"

    env_name = "${var.env_name}"
    kmslogging_service_enabled = "${var.kmslogging_enabled}"
    sns_topic_dead_letter_arn = "${var.slack_events_sns_hook_arn}"
}
