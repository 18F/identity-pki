module "kms_logging" {
    source = "github.com/18F/identity-terraform//kms_log?ref=e4f516aea6385afe32a3f416c0b6e2bd4707ccd4"
    #source = "../../identity-terraform/kms_log"

    env_name = "${var.env_name}"
    kmslogging_service_enabled = "${var.kmslogging_enabled}"
}