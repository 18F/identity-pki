module "kms_logging" {
    source = "github.com/18F/identity-terraform//kms_log?ref=a5069fac498340b276eb1cc5d4a0817138a3015d"
    #source = "../../identity-terraform/kms_log"

    env_name = "${var.env_name}"
    kmslogging_service_enabled = "${var.kmslogging_enabled}"
}
