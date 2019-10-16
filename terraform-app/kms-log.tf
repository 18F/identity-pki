module "kms_logging" {
    source = "github.com/18F/identity-terraform//kms_log?ref=b0638c6239c281ac58f7b08d6b04ab6cef61a348"
    #source = "../../identity-terraform/kms_log"

    env_name = "${var.env_name}"
    kmslogging_service_enabled = "${var.kmslogging_enabled}"
    sns_topic_dead_letter_arn = "${var.slack_events_sns_hook_arn}"
}
