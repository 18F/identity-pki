module "kms_logging" {
    source = "github.com/18F/identity-terraform//kms_log?ref=809753009069f5f850490b510d5361f3ff2a7b08"
    #source = "../../identity-terraform/kms_log"

    env_name = "${var.env_name}"
    kmslogging_service_enabled = "${var.kmslogging_enabled}"
}