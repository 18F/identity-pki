module "kms_logging" {
    source = "github.com/18F/identity-terraform//kms_log?ref=c1b7fec93b26cee22ba20246486fd17062c654df"
    #source = "../../identity-terraform/kms_log"

    env_name = "${var.env_name}"
    kmslogging_service_enabled = "${var.kmslogging_enabled}"
}
