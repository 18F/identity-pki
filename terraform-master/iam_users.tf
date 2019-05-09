# users
module "brian_crissup" {
    source = "terraform-aws-modules/iam/aws//modules/iam-user"
    name = "brian.crissup"
    password_length = "${local.password_length}"
    password_reset_required = true
    force_destroy = true
    create_iam_access_key = false
    pgp_key = "keybase:test"  
}

module "andy_brody" {
    source = "terraform-aws-modules/iam/aws//modules/iam-user"
    name = "andy.brody"
    password_length = "${local.password_length}"
    password_reset_required = true
    force_destroy = true
    create_iam_access_key = false
    pgp_key = "keybase:test"
}

module "brett_mcparland" {
    source = "terraform-aws-modules/iam/aws//modules/iam-user"
    name = "brett.mcparland"
    password_length = "${local.password_length}"
    password_reset_required = true
    force_destroy = true
    create_iam_access_key = false
    pgp_key = "keybase:test"
}

module "clara_bridges" {
    source = "terraform-aws-modules/iam/aws//modules/iam-user"
    name = "clara.bridges"
    password_length = "${local.password_length}"
    password_reset_required = true
    force_destroy = true
    create_iam_access_key = false
    pgp_key = "keybase:test"
}

module "jonathan_hooper" {
    source = "terraform-aws-modules/iam/aws//modules/iam-user"
    name = "jonathan.hooper"
    password_length = "${local.password_length}"
    password_reset_required = true
    force_destroy = true
    create_iam_access_key = false
    pgp_key = "keybase:test"
}

module "justin_grevich" {
    source = "terraform-aws-modules/iam/aws//modules/iam-user"
    name = "justin.grevich"
    password_length = "${local.password_length}"
    password_reset_required = true
    force_destroy = true
    create_iam_access_key = false
    pgp_key = "keybase:test"
}

module "laura_gerhardt" {
    source = "terraform-aws-modules/iam/aws//modules/iam-user"
    name = "laura.gerhardt"
    password_length = "${local.password_length}"
    password_reset_required = true
    force_destroy = true
    create_iam_access_key = false
    pgp_key = "keybase:test"
}

module "mark_ryan" {
    source = "terraform-aws-modules/iam/aws//modules/iam-user"
    name = "mark.ryan"
    password_length = "${local.password_length}"
    password_reset_required = true
    force_destroy = true
    create_iam_access_key = false
    pgp_key = "keybase:test"
}

# module "mossadeq_zia" {
#     source = "terraform-aws-modules/iam/aws//modules/iam-user"
#     name = "mossadeq.zia"
#     password_length = "${local.password_length}"
#     password_reset_required = true
#     force_destroy = true
#     create_iam_access_key = false
#     pgp_key = "keybase:test"
# }

module "rajat_varuni" {
    source = "terraform-aws-modules/iam/aws//modules/iam-user"
    name = "rajat.varuni"
    password_length = "${local.password_length}"
    password_reset_required = true
    force_destroy = true
    create_iam_access_key = false
    pgp_key = "keybase:test"
}

module "steve_urciuoli" {
    source = "terraform-aws-modules/iam/aws//modules/iam-user"
    name = "steve.urciuoli"
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
        "${module.andy_brody.this_iam_user_name}",
        "${module.brian_crissup.this_iam_user_name}",
        "${module.justin_grevich.this_iam_user_name}"
    ]
    policy_arn = "${aws_iam_policy.master_full_administrator.arn}"
}

resource "aws_iam_policy_attachment" "sandbox_full_administrator" {
    name = "sandbox_full_administrator"
    users = [
        "${module.andy_brody.this_iam_user_name}",
        "${module.justin_grevich.this_iam_user_name}"
    ]
    policy_arn = "${aws_iam_policy.sandbox_assume_full_administrator.arn}"
}

# resource "aws_iam_policy_attachment" "production_full_administrator" {
#     name = "production_full_administrator"
#     users = [
#         "${module.andy_brody.this_iam_user_name}"
#     ]
#     policy_arn = "${aws_iam_policy.production_assume_full_administrator.arn}"
# }

resource "aws_iam_policy_attachment" "sandbox_power_user" {
    name = "sandbox_power_user"
    users = [
        "${module.andy_brody.this_iam_user_name}",
        "${module.brian_crissup.this_iam_user_name}",
        "${module.steve_urciuoli.this_iam_user_name}",
        "${module.rajat_varuni.this_iam_user_name}",
        "${module.justin_grevich.this_iam_user_name}",
        "${module.clara_bridges.this_iam_user_name}",
        "${module.mark_ryan.this_iam_user_name}",
        "${module.laura_gerhardt.this_iam_user_name}"
    ]
    policy_arn = "${aws_iam_policy.sandbox_assume_power_user.arn}"
}

# resource "aws_iam_policy_attachment" "production_power_user" {
#     name = "production_power_user"
#     users = [
#         "${module.andy_brody.this_iam_user_name}",
#         "${module.brian_crissup.this_iam_user_name}",
#         "${module.steve_urciuoli.this_iam_user_name}",
#         "${module.jonathan_hooper.this_iam_user_name}"
#     ]
#     policy_arn = "${aws_iam_policy.production_assume_power_user.arn}"
# }

# resource "aws_iam_policy_attachment" "production_readonly" {
#     name = "production_power_user"
#     users = [
#         "${module.andy_brody.this_iam_user_name}",
#         "${module.brian_crissup.this_iam_user_name}",
#         "${module.steve_urciuoli.this_iam_user_name}",
#         "${module.jonathan_hooper.this_iam_user_name}"
#     ]
#     policy_arn = "${aws_iam_policy.production_assume_readonly.arn}"
# }

resource "aws_iam_policy_attachment" "sandbox_readonly" {
    name = "production_power_user"
    users = [
        "${module.andy_brody.this_iam_user_name}",
        "${module.brian_crissup.this_iam_user_name}",
        "${module.steve_urciuoli.this_iam_user_name}",
        "${module.jonathan_hooper.this_iam_user_name}"
    ]
    policy_arn = "${aws_iam_policy.sandbox_assume_readonly.arn}"
}