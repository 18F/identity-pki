module "kms_logging" {
    source = "github.com/18F/identity-terraform//kms_log?ref=326f65d857ad7a4577a94f56a941c14763915acb"
    #source = "../../identity-terraform/kms_log"

    env_name = "${var.env_name}"
    kmslogging_service_enabled = "${var.kmslogging_enabled}"
    sns_topic_dead_letter_arn = "${var.slack_events_sns_hook_arn}"
}
