module "kms_logging" {
    source = "github.com/18F/identity-terraform//kms_log?ref=ebaf7cb3d371fcadc8770406280d40860adf5f7e"
    #source = "../../identity-terraform/kms_log"

    env_name = "${var.env_name}"
    kmslogging_service_enabled = "${var.kmslogging_enabled}"
}