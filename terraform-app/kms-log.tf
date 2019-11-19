module "kms_logging" {
    source = "github.com/18F/identity-terraform//kms_log?ref=a74f41d1549e79c0323e143e9ce33e85b2cbf50a"
    #source = "../../identity-terraform/kms_log"

    env_name = "${var.env_name}"
    kmslogging_service_enabled = "${var.kmslogging_enabled}"
    sns_topic_dead_letter_arn = "${var.slack_events_sns_hook_arn}"
}
