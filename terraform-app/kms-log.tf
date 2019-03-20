module "kms_logging" {
    source = "github.com/18F/identity-terraform//kms_log?ref=e7dbea9542b64a5df8e8c8367cbd9674bd86c9a0"
    #source = "../../identity-terraform/kms_log"

    env_name = "${var.env_name}"
    kmslogging_service_enabled = "${var.kmslogging_enabled}"
}
