module "kms_logging" {
    source = "github.com/18F/identity-terraform//kms_log?ref=9c13801ac0be5c3e1fa773674f75a368dc450634"
    #source = "../../identity-terraform/kms_log"

    env_name = "${var.env_name}"
    kmslogging_service_enabled = "${var.kmslogging_enabled}"
    sns_topic_dead_letter_arn = "${var.slack_events_sns_hook_arn}"
}
