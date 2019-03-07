module "kms_logging" {
    source = "github.com/18F/identity-terraform//kms_log?ref=70091f1bf40326492b4e473f705f12edda7541c5"
    #source = "../../identity-terraform/kms_log"

    env_name = "${var.env_name}"
    kmslogging_service_enabled = "${var.kmslogging_enabled}"
}