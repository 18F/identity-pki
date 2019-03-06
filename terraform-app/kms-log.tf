module "kms_logging" {
    source = "github.com/18F/identity-terraform//kms_log?ref=13751594b89fa590d6d5f75140f87fdbb1015747"
    #source = "../../identity-terraform/kms_log"

    env_name = "${var.env_name}"
    kmslogging_service_enabled = "${var.kmslogging_enabled}"
}