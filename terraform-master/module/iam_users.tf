# create users
resource "aws_iam_user" "aaron_chapman" {
  name          = "aaron.chapman"
  force_destroy = true
}

resource "aws_iam_user" "andy_brody" {
  name          = "andy.brody"
  force_destroy = true
}

resource "aws_iam_user" "amit_freeman" {
  name          = "amit.freeman"
  force_destroy = true
}

resource "aws_iam_user" "brian_crissup" {
  name          = "brian.crissup"
  force_destroy = true
}

resource "aws_iam_user" "brett_mcparland" {
  name          = "brett.mcparland"
  force_destroy = true
}

resource "aws_iam_user" "douglas_price" {
  name          = "douglas.price"
  force_destroy = true
}

resource "aws_iam_user" "jonathan_hooper" {
  name          = "jonathan.hooper"
  force_destroy = true
}

resource "aws_iam_user" "jonathan_pirro" {
  name          = "jonathan.pirro"
  force_destroy = true
}

resource "aws_iam_user" "justin_grevich" {
  name          = "justin.grevich"
  force_destroy = true
}

resource "aws_iam_user" "jennifer_wagner" {
  name          = "jennifer.wagner"
  force_destroy = true
}

resource "aws_iam_user" "karla_rodriguez" {
  name          = "karla.rodriguez"
  force_destroy = true
}

resource "aws_iam_user" "laura_gerhardt" {
  name          = "laura.gerhardt"
  force_destroy = true
}

resource "aws_iam_user" "likhitha_patha" {
  name          = "likhitha.patha"
  force_destroy = true
}

resource "aws_iam_user" "mossadeq_zia" {
  name          = "mossadeq.zia"
  force_destroy = true
}

resource "aws_iam_user" "rajat_varuni" {
  name          = "rajat.varuni"
  force_destroy = true
}

resource "aws_iam_user" "steve_urciuoli" {
  name          = "steve.urciuoli"
  force_destroy = true
}

resource "aws_iam_user" "stephen_grow" {
  name          = "stephen.grow"
  force_destroy = true
}

resource "aws_iam_user" "steven_harms" {
  name          = "steven.harms"
  force_destroy = true
}

resource "aws_iam_user" "thomas_black" {
  name          = "thomas.black"
  force_destroy = true
}

# policy attachments
# attach this policy to every user
resource "aws_iam_policy_attachment" "manage_your_account" {
  name = "manage_your_account"
  users = [
    aws_iam_user.aaron_chapman.name,
    aws_iam_user.andy_brody.name,
    aws_iam_user.amit_freeman.name,
    aws_iam_user.brett_mcparland.name,
    aws_iam_user.brian_crissup.name,
    aws_iam_user.douglas_price.name,
    aws_iam_user.jonathan_hooper.name,
    aws_iam_user.jonathan_pirro.name,
    aws_iam_user.justin_grevich.name,
    aws_iam_user.jennifer_wagner.name,
    aws_iam_user.karla_rodriguez.name,
    aws_iam_user.laura_gerhardt.name,
    aws_iam_user.likhitha_patha.name,
    aws_iam_user.mossadeq_zia.name,
    aws_iam_user.rajat_varuni.name,
    aws_iam_user.stephen_grow.name,
    aws_iam_user.steve_urciuoli.name,
    aws_iam_user.steven_harms.name,
    aws_iam_user.thomas_black.name,
  ]
  policy_arn = aws_iam_policy.manage_your_account.arn
}

resource "aws_iam_policy_attachment" "master_full_administrator" {
  name = "master_full_administrator"
  users = [
    aws_iam_user.andy_brody.name,
    aws_iam_user.amit_freeman.name,
    aws_iam_user.brian_crissup.name,
    aws_iam_user.jonathan_pirro.name,
    aws_iam_user.justin_grevich.name,
    aws_iam_user.mossadeq_zia.name,
    aws_iam_user.steven_harms.name,
  ]
  policy_arn = aws_iam_policy.master_full_administrator.arn
}

resource "aws_iam_policy_attachment" "sandbox_full_administrator" {
  name = "sandbox_full_administrator"
  users = [
    aws_iam_user.andy_brody.name,
    aws_iam_user.amit_freeman.name,
    aws_iam_user.jonathan_pirro.name,
    aws_iam_user.justin_grevich.name,
    aws_iam_user.mossadeq_zia.name,
    aws_iam_user.steven_harms.name,
  ]
  policy_arn = aws_iam_policy.sandbox_assume_full_administrator.arn
}

# resource "aws_iam_policy_attachment" "production_full_administrator" {
#     name = "production_full_administrator"
#     users = [
#         "${aws_iam_user.andy_brody.name}",
#         "${aws_iam_user.mossadeq_zia.name}"
#     ]
#     policy_arn = "${aws_iam_policy.production_assume_full_administrator.arn}"
# }

resource "aws_iam_policy_attachment" "sandbox_power_user" {
  name = "sandbox_power_user"
  users = [
    aws_iam_user.andy_brody.name,
    aws_iam_user.amit_freeman.name,
    aws_iam_user.aaron_chapman.name,
    aws_iam_user.brian_crissup.name,
    aws_iam_user.justin_grevich.name,
    aws_iam_user.jonathan_pirro.name,
    aws_iam_user.laura_gerhardt.name,
    aws_iam_user.mossadeq_zia.name,
    aws_iam_user.rajat_varuni.name,
    aws_iam_user.steven_harms.name,
    aws_iam_user.steve_urciuoli.name,
  ]
  policy_arn = aws_iam_policy.sandbox_assume_power_user.arn
}

# resource "aws_iam_policy_attachment" "production_power_user" {
#     name = "production_power_user"
#     users = [
#         "${aws_iam_user.andy_brody.name}",
#         "${aws_iam_user.brian_crissup.name}",
#         "${aws_iam_user.mossadeq_zia.name}",
#         "${aws_iam_user.steve_urciuoli.name}",
#         "${aws_iam_user.jonathan_hooper.name}"
#     ]
#     policy_arn = "${aws_iam_policy.production_assume_power_user.arn}"
# }

#resource "aws_iam_policy_attachment" "production_appdev" {
#    name = "production_appdev"
#    users = [
#        "${aws_iam_user.steve_urciuoli.name}",
#        "${aws_iam_user.jonathan_hooper.name}"
#    ]
#    policy_arn = "${aws_iam_policy.production_assume_appdev.arn}"
#}

# resource "aws_iam_policy_attachment" "production_readonly" {
#     name = "production_readonly"
#     users = [
#         "${aws_iam_user.andy_brody.name}",
#         "${aws_iam_user.brian_crissup.name}",
#         "${aws_iam_user.mossadeq_zia.name}",
#         "${aws_iam_user.steve_urciuoli.name}",
#         "${aws_iam_user.jonathan_hooper.name}"
#     ]
#     policy_arn = "${aws_iam_policy.production_assume_readonly.arn}"
# }

resource "aws_iam_policy_attachment" "sandbox_readonly" {
  name = "sandbox_readonly"
  users = [
    aws_iam_user.andy_brody.name,
    aws_iam_user.amit_freeman.name,
    aws_iam_user.brian_crissup.name,
    aws_iam_user.jonathan_hooper.name,
    aws_iam_user.jonathan_pirro.name,
    aws_iam_user.justin_grevich.name,
    aws_iam_user.mossadeq_zia.name,
    aws_iam_user.steven_harms.name,
    aws_iam_user.steve_urciuoli.name,
  ]
  policy_arn = aws_iam_policy.sandbox_assume_readonly.arn
}

resource "aws_iam_policy_attachment" "production_socadministrator" {
    name = "production_socadministrator"
    users = [
        aws_iam_user.brett_mcparland.name,
        aws_iam_user.mossadeq_zia.name,
        aws_iam_user.steven_harms.name,
    ]
    policy_arn = aws_iam_policy.production_assume_socadministrator.arn
}

resource "aws_iam_policy_attachment" "sandbox_socadministrator" {
    name = "sandbox_socadministrator"
    users = [
        aws_iam_user.brett_mcparland.name,
        aws_iam_user.mossadeq_zia.name,
        aws_iam_user.rajat_varuni.name,
        aws_iam_user.steven_harms.name,
    ]
    policy_arn = aws_iam_policy.sandbox_assume_socadministrator.arn
}

resource "aws_iam_policy_attachment" "master_socadministrator" {
    name = "sandbox_socadministrator"
    users = [
        aws_iam_user.brett_mcparland.name,
        aws_iam_user.mossadeq_zia.name,
        aws_iam_user.rajat_varuni.name,
        aws_iam_user.steven_harms.name,
    ]
    policy_arn = aws_iam_policy.master_socadministrator.arn
}
