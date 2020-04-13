# create users
resource "aws_iam_user" "aaron_chapman" {
  name          = "aaron.chapman"
  force_destroy = true
}

resource "aws_iam_user" "akhlaq_khan" {
  name          = "akhlaq.khan"
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

resource "aws_iam_user" "christopher_billas" {
  name          = "christopher.billas"
  force_destroy = true
}

resource "aws_iam_user" "clinton_troxel" {
  name          = "clinton.troxel"
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

resource "aws_iam_user" "likhitha_patha" {
  name          = "likhitha.patha"
  force_destroy = true
}

resource "aws_iam_user" "mossadeq_zia" {
  name          = "mossadeq.zia"
  force_destroy = true
}

resource "aws_iam_user" "paul_hirsch" {
  name          = "paul.hirsch"
  force_destroy = true
}

resource "aws_iam_user" "rajat_varuni" {
  name          = "rajat.varuni"
  force_destroy = true
}

resource "aws_iam_user" "silke_dannemann" {
  name          = "silke.dannemann"
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

resource "aws_iam_user" "timothy_spencer" {
  name          = "timothy.spencer"
  force_destroy = true
}

resource "aws_iam_user" "zachary_margolis" {
  name          = "zach.margolis"
  force_destroy = true
}

# policy attachments
# attach this policy to every user
resource "aws_iam_policy_attachment" "manage_your_account" {
  name = "manage_your_account"
  users = [
    aws_iam_user.aaron_chapman.name,
    aws_iam_user.akhlaq_khan.name,
    aws_iam_user.amit_freeman.name,
    aws_iam_user.brett_mcparland.name,
    aws_iam_user.brian_crissup.name,
    aws_iam_user.christopher_billas.name,
    aws_iam_user.clinton_troxel.name,
    aws_iam_user.douglas_price.name,
    aws_iam_user.jonathan_hooper.name,
    aws_iam_user.jonathan_pirro.name,
    aws_iam_user.justin_grevich.name,
    aws_iam_user.jennifer_wagner.name,
    aws_iam_user.karla_rodriguez.name,
    aws_iam_user.likhitha_patha.name,
    aws_iam_user.mossadeq_zia.name,
    aws_iam_user.paul_hirsch.name,
    aws_iam_user.rajat_varuni.name,
    aws_iam_user.silke_dannemann.name,
    aws_iam_user.stephen_grow.name,
    aws_iam_user.steve_urciuoli.name,
    aws_iam_user.steven_harms.name,
    aws_iam_user.thomas_black.name,
    aws_iam_user.timothy_spencer.name,
    aws_iam_user.zachary_margolis.name,
  ]
  policy_arn = aws_iam_policy.manage_your_account.arn
}

######## FullAdministrator ########
resource "aws_iam_policy_attachment" "master_full_administrator" {
  name = "master_full_administrator"
  users = [
    aws_iam_user.amit_freeman.name,
    aws_iam_user.jonathan_pirro.name,
    aws_iam_user.justin_grevich.name,
    aws_iam_user.mossadeq_zia.name,
    aws_iam_user.paul_hirsch.name,
    aws_iam_user.steven_harms.name,
    aws_iam_user.timothy_spencer.name,
  ]
  policy_arn = aws_iam_policy.master_full_administrator.arn
}

resource "aws_iam_policy_attachment" "sandbox_full_administrator" {
  name = "sandbox_full_administrator"
  users = [
    aws_iam_user.amit_freeman.name,
    aws_iam_user.jonathan_pirro.name,
    aws_iam_user.justin_grevich.name,
    aws_iam_user.mossadeq_zia.name,
    aws_iam_user.paul_hirsch.name,
    aws_iam_user.steven_harms.name,
    aws_iam_user.timothy_spencer.name,
  ]
  policy_arn = aws_iam_policy.sandbox_assume_full_administrator.arn
}

resource "aws_iam_policy_attachment" "production_full_administrator" {
  name = "production_full_administrator"
  users = [
    aws_iam_user.amit_freeman.name,
    aws_iam_user.jonathan_pirro.name,
    aws_iam_user.justin_grevich.name,
    aws_iam_user.mossadeq_zia.name,
    aws_iam_user.paul_hirsch.name,
    aws_iam_user.steven_harms.name,
    aws_iam_user.timothy_spencer.name,
  ]
  policy_arn = aws_iam_policy.production_assume_full_administrator.arn
}

resource "aws_iam_policy_attachment" "sandbox_sms_full_administrator" {
  name = "sandbox_sms_full_administrator"
  users = [
    aws_iam_user.amit_freeman.name,
    aws_iam_user.jonathan_pirro.name,
    aws_iam_user.justin_grevich.name,
    aws_iam_user.mossadeq_zia.name,
    aws_iam_user.paul_hirsch.name,
    aws_iam_user.steven_harms.name,
    aws_iam_user.timothy_spencer.name,
  ]
  policy_arn = aws_iam_policy.sandbox_sms_assume_full_administrator.arn
}

resource "aws_iam_policy_attachment" "production_sms_full_administrator" {
  name = "production_sms_full_administrator"
  users = [
    aws_iam_user.amit_freeman.name,
    aws_iam_user.jonathan_pirro.name,
    aws_iam_user.justin_grevich.name,
    aws_iam_user.mossadeq_zia.name,
    aws_iam_user.paul_hirsch.name,
    aws_iam_user.steven_harms.name,
    aws_iam_user.timothy_spencer.name,
  ]
  policy_arn = aws_iam_policy.production_sms_assume_full_administrator.arn
}

resource "aws_iam_policy_attachment" "production_analytics_full_administrator" {
  name = "production_analytics_full_administrator"
  users = [
    aws_iam_user.amit_freeman.name,
    aws_iam_user.jonathan_pirro.name,
    aws_iam_user.justin_grevich.name,
    aws_iam_user.mossadeq_zia.name,
    aws_iam_user.paul_hirsch.name,
    aws_iam_user.steven_harms.name,
    aws_iam_user.timothy_spencer.name,
  ]
  policy_arn = aws_iam_policy.production_analytics_assume_full_administrator.arn
}

resource "aws_iam_policy_attachment" "secops_full_administrator" {
  name = "secops_full_administrator"
  users = [
    aws_iam_user.amit_freeman.name,
    aws_iam_user.jonathan_pirro.name,
    aws_iam_user.justin_grevich.name,
    aws_iam_user.mossadeq_zia.name,
    aws_iam_user.paul_hirsch.name,
    aws_iam_user.steven_harms.name,
    aws_iam_user.timothy_spencer.name,
  ]
  policy_arn = aws_iam_policy.secops_assume_full_administrator.arn
}

######## PowerUser ########
resource "aws_iam_policy_attachment" "sandbox_power_user" {
  name = "sandbox_power_user"
  users = [
    aws_iam_user.aaron_chapman.name,
    aws_iam_user.brian_crissup.name,
    aws_iam_user.clinton_troxel.name,
    aws_iam_user.douglas_price.name,
    aws_iam_user.rajat_varuni.name,
    aws_iam_user.stephen_grow.name,
    aws_iam_user.steve_urciuoli.name,
    aws_iam_user.zachary_margolis.name,
  ]
  policy_arn = aws_iam_policy.sandbox_assume_power_user.arn
}

resource "aws_iam_policy_attachment" "production_power_user" {
  name = "production_power_user"
  users = [
    aws_iam_user.brian_crissup.name,
    aws_iam_user.clinton_troxel.name,
    aws_iam_user.douglas_price.name,
    aws_iam_user.jonathan_hooper.name,
    aws_iam_user.steve_urciuoli.name,
    aws_iam_user.stephen_grow.name,
    aws_iam_user.zachary_margolis.name,
  ]
  policy_arn = aws_iam_policy.production_assume_power_user.arn
}

######## AppDev ########
resource "aws_iam_policy_attachment" "production_appdev" {
  name = "production_appdev"
  users = [
    aws_iam_user.clinton_troxel.name,
    aws_iam_user.steve_urciuoli.name,
    aws_iam_user.jonathan_hooper.name,
    aws_iam_user.zachary_margolis.name,
  ]
  policy_arn = aws_iam_policy.production_assume_appdev.arn
}

######## ReadOnly ########
resource "aws_iam_policy_attachment" "production_readonly" {
  name = "production_readonly"
  users = [
    aws_iam_user.brian_crissup.name,
    aws_iam_user.jonathan_hooper.name,
    aws_iam_user.mossadeq_zia.name,
    aws_iam_user.steve_urciuoli.name,
  ]
  policy_arn = aws_iam_policy.production_assume_readonly.arn
}

resource "aws_iam_policy_attachment" "sandbox_readonly" {
  name = "sandbox_readonly"
  users = [
    aws_iam_user.jonathan_hooper.name,
    aws_iam_user.stephen_grow.name,
    aws_iam_user.steve_urciuoli.name,
  ]
  policy_arn = aws_iam_policy.sandbox_assume_readonly.arn
}

######## SOCAdministrator ########
resource "aws_iam_policy_attachment" "production_socadministrator" {
  name = "production_socadministrator"
  users = [
    aws_iam_user.brett_mcparland.name,
    aws_iam_user.rajat_varuni.name,
  ]
  policy_arn = aws_iam_policy.production_assume_socadministrator.arn
}

resource "aws_iam_policy_attachment" "sandbox_socadministrator" {
  name = "sandbox_socadministrator"
  users = [
    aws_iam_user.brett_mcparland.name,
    aws_iam_user.rajat_varuni.name,
  ]
  policy_arn = aws_iam_policy.sandbox_assume_socadministrator.arn
}

resource "aws_iam_policy_attachment" "master_socadministrator" {
  name = "sandbox_socadministrator"
  users = [
    aws_iam_user.brett_mcparland.name,
    aws_iam_user.rajat_varuni.name,
  ]
  policy_arn = aws_iam_policy.master_socadministrator.arn
}

resource "aws_iam_policy_attachment" "production_sms_socadministrator" {
  name = "production_sms_socadministrator"
  users = [
    aws_iam_user.brett_mcparland.name,
    aws_iam_user.rajat_varuni.name,
  ]
  policy_arn = aws_iam_policy.production_sms_assume_socadministrator.arn
}

resource "aws_iam_policy_attachment" "sandbox_sms_socadministrator" {
  name = "sandbox_sms_socadministrator"
  users = [
    aws_iam_user.brett_mcparland.name,
    aws_iam_user.rajat_varuni.name,
  ]
  policy_arn = aws_iam_policy.sandbox_sms_assume_socadministrator.arn
}

resource "aws_iam_policy_attachment" "production_analytics_socadministrator" {
  name = "production_analytics_socadministrator"
  users = [
    aws_iam_user.brett_mcparland.name,
    aws_iam_user.rajat_varuni.name,
  ]
  policy_arn = aws_iam_policy.production_analytics_assume_socadministrator.arn
}

######## KMSAdmin ########
resource "aws_iam_policy_attachment" "production_kmsadministrator" {
  name = "production_kmsadministrator"
  users = [
    aws_iam_user.rajat_varuni.name,
    aws_iam_user.steve_urciuoli.name,
    aws_iam_user.jonathan_hooper.name,
    aws_iam_user.brian_crissup.name,
    aws_iam_user.mossadeq_zia.name,
  ]
  policy_arn = aws_iam_policy.production_assume_kmsadministrator.arn
}

resource "aws_iam_policy_attachment" "sandbox_kmsadministrator" {
  name = "sandbox_kmsadministrator"
  users = [
    aws_iam_user.steve_urciuoli.name,
    aws_iam_user.brett_mcparland.name,
    aws_iam_user.rajat_varuni.name,
    aws_iam_user.justin_grevich.name,
    aws_iam_user.brian_crissup.name,
    aws_iam_user.mossadeq_zia.name,
    aws_iam_user.jonathan_hooper.name,
  ]
  policy_arn = aws_iam_policy.sandbox_assume_kmsadministrator.arn
}
