module "kms_logging" {
    source = "github.com/18F/identity-terraform//kms_log?ref=de30ee5c0abebd6aa8d33d7d8d2152ba74e85a78"
    #source = "../../identity-terraform/kms_log"

    env_name = "${var.env_name}"
    kmslogging_service_enabled = "${var.kmslogging_enabled}"
    sns_topic_dead_letter_arn = "${var.slack_events_sns_hook_arn}"
}
