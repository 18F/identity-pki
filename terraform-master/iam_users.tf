module "bcrissup" {
    source = "terraform-aws-modules/iam/aws//modules/iam-user"
    name = "b.crissup"
    force_destroy = true
    pgp_key = "keybase:test"
    password_reset_required = true
}

module "abrody" {
    source = "terraform-aws-modules/iam/aws//modules/iam-user"
    name = "a.brody"
    force_destroy = true
    pgp_key = "keybase:test"
    password_reset_required = true
}

