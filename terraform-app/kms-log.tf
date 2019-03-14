module "kms_logging" {
    source = "github.com/18F/identity-terraform//kms_log?ref=7cea09571f1384b3b61143427f2563c951114e78"
    #source = "../../identity-terraform/kms_log"

    env_name = "${var.env_name}"
    kmslogging_service_enabled = "${var.kmslogging_enabled}"
}
