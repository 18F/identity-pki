module "kms_logging" {
    #source = "github.com/18F/identity-terraform//kms_log?ref=3caf222d0b191a24200c7e901db57ea8031af821"
    source = "../../identity-terraform/kms_log"

    env_name = "${var.env_name}"
}