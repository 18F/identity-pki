# users
module "bcrissup" {
    source = "terraform-aws-modules/iam/aws//modules/iam-user"
    name = "b.crissup"
    password_length = "${local.password_length}"
    password_reset_required = true
    force_destroy = true
    create_iam_access_key = false
    pgp_key = "keybase:test"  
}

module "abrody" {
    source = "terraform-aws-modules/iam/aws//modules/iam-user"
    name = "a.brody"
    password_length = "${local.password_length}"
    password_reset_required = true
    force_destroy = true
    create_iam_access_key = false
    pgp_key = "keybase:test"
}

# policy attachments
resource "aws_iam_policy_attachment" "master_full_administrator" {
    name = "master_full_administrator"
    users = [
        "${module.abrody.this_iam_user_name}",
        "${module.bcrissup.this_iam_user_name}"
    ]
    policy_arn = "${aws_iam_policy.master_full_administrator.arn}"
}

resource "aws_iam_policy_attachment" "sandbox_full_administrator" {
    name = "sandbox_full_administrator"
    users = [
        "${module.abrody.this_iam_user_name}",
        "${module.bcrissup.this_iam_user_name}"
    ]
    policy_arn = "${aws_iam_policy.sandbox_assume_full_administrator.arn}"
}
