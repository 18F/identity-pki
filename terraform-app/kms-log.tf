module "kms_logging" {
    source = "github.com/18F/identity-terraform//kms_log?ref=ce5391322e3f38d8ba4359997b16dc5937330d22"
    #source = "../../identity-terraform/kms_log"

    env_name = "${var.env_name}"
    kmslogging_service_enabled = "${var.kmslogging_enabled}"
    sns_topic_dead_letter_arn = "${var.slack_events_sns_hook_arn}"
}
