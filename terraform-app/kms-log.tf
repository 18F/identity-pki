module "kms_logging" {
    source = "github.com/18F/identity-terraform//kms_log?ref=674021d6dc358b255117edd78cee2579ad295f65"
    #source = "../../identity-terraform/kms_log"

    env_name = "${var.env_name}"
    kmslogging_service_enabled = "${var.kmslogging_enabled}"
}