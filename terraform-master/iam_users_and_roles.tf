module "bcrissup" {
    source = "terraform-aws-modules/iam/aws//modules/iam-user"
    name = "b.crissup"
    force_destroy = true
    create_iam_access_key = false
    pgp_key = "keybase:test"
    password_reset_required = true
}

module "abrody" {
    source = "terraform-aws-modules/iam/aws//modules/iam-user"
    name = "a.brody"
    force_destroy = true
    create_iam_access_key = false
    pgp_key = "keybase:test"
    password_reset_required = true
}

resource "aws_iam_policy_attachment" "assume_full_administrator" {
    name = "assume_full_administrator"
    users = [
        "${module.abrody.this_iam_user_name}",
        "${module.bcrissup.this_iam_user_name}"
    ]
    policy_arn = "${aws_iam_policy.assume_full_administrator.arn}"
}
