module "kms_logging" {
    source = "github.com/18F/identity-terraform//kms_log?ref=fecbe82971d8f1429ba78be872d55235c41cc3dc"
    #source = "../../identity-terraform/kms_log"

    env_name = "${var.env_name}"
    kmslogging_service_enabled = "${var.kmslogging_enabled}"
    sns_topic_dead_letter_arn = "${var.slack_events_sns_hook_arn}"
}
