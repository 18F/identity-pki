provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["340731855345"] # require login-master
  profile             = "login-master"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  region            = "us-west-2"
  master_account_id = "340731855345"

  aws_account_types = {
    "Master" = [
      "340731855345" # login-master
    ],
    "Prod" = [
      "555546682965", # login-prod
      "472911866628", # login-sms-prod
      "217680906704" # login-secops-prod
    ],
    "Sandbox" = [
      "894947205914", # login-sandbox
      "035466892286", # login-sms-sandbox
      "138431511372", # login-secops-dev
      "034795980528" # login-interviews
    ],
    "Analytics" = [
      "461353137281" # login-analytics
    ]
  }

  group_role_map = {
    "appdev" = [
      { "PowerUser"         = [ "Sandbox" ] },
      { "ReadOnly"          = [ "Sandbox" ] },
      { "Terraform"         = [ "Sandbox" ] }
    ],
    "analytics" = [
      { "Analytics"         = [ "Sandbox", "Prod" ] }
    ],
    "apponcall" = [
      { "PowerUser"         = [ "Sandbox", "Prod" ] },
      { "ReadOnly"          = [ "Sandbox", "Prod" ] },
      { "Terraform"         = [ "Sandbox" ] }
    ],
    "bizops" = [
      { "ReportsReadOnly"   = [ "Sandbox", "Prod" ] }
    ],
    "devops" = [
      { "FullAdministrator" = [ "Sandbox", "Prod", "Master", "Analytics" ] },
      { "PowerUser"         = [ "Sandbox", "Prod" ] },
      { "ReadOnly"          = [ "Sandbox", "Prod" ] },
      { "Terraform"         = [ "Sandbox", "Prod", "Master" ] },
      { "KMSAdministrator"  = [ "Sandbox", "Analytics" ] }
    ],
    "finops" = [
      { "BillingReadOnly"   = [ "Sandbox", "Prod" ] }
    ],
    "secops" = [
      { "FullAdministrator" = [ "Sandbox", "Prod", "Master" ] },
      { "ReadOnly"          = [ "Sandbox", "Prod" ] },
      { "KMSAdministrator"  = [ "Sandbox" ] }
    ],
    "soc" = [
      { "ReadOnly"          = [ "Sandbox", "Prod", "Master", "Analytics" ] },
      { "SOCAdministrator"  = [ "Sandbox", "Prod", "Master", "Analytics" ] }
    ],
    "keymasters" = [
      { "KMSAdministrator"  = [ "Prod" ] }
    ]
  }

  role_list = [
    "Analytics",
    "Auditor",
    "FullAdministrator",
    "PowerUser",
    "ReadOnly",
    "Terraform",
    "BillingReadOnly",
    "ReportsReadOnly",
    "KMSAdministrator",
    "SOCAdministrator",
  ]

  # User to group mappings - Groups defined in ../module/iam_groups.tf
  user_map = {
    "aaron.chapman"      = ["appdev", "apponcall"],
    "akhlaq.khan"        = ["analytics", "finops", "bizops"],
    "alex.mathews"       = ["appdev", "apponcall"],
    "amit.freeman"       = ["devops"],
    "amos.stone"         = ["analytics"],
    "andrew.duthie"      = ["appdev", "apponcall"],
    "brett.mcparland"    = ["secops", "soc"],
    "brian.crissup"      = ["devops", "keymasters"],
    "chris.manger"       = ["bizops", "finops"],
    "clinton.troxel"     = ["appdev"],
    "colin.murphy"       = ["bizops"],
    "diondra.humphries"  = ["bizops"],
    "douglas.price"      = ["appdev", "apponcall", "bizops"],
    "jeff.shultz"        = ["analytics"],
    "john.yuda"          = ["analytics"],
    "jonathan.hooper"    = ["appdev", "apponcall", "keymasters"],
    "jonathan.pirro"     = ["devops"],
    "julia.elman"        = ["analytics"],
    "justin.grevich"     = ["devops"],
    "kendrick.daniel"    = ["bizops"],
    "michael.antiporta"  = ["analytics"],
    "mitchell.henke"     = ["appdev", "apponcall"],
    "mossadeq.zia"       = ["devops", "secops", "keymasters"],
    "oren.kanner"        = ["appdev", "bizops"],
    "phil.lam"           = ["analytics"],
    "paul.hirsch"        = ["devops"],
    "sierra.toler"       = ["bizops"],
    "stephanie.rivera"   = ["bizops"],
    "steve.urciuoli"     = ["appdev", "apponcall", "keymasters"],
    "steven.harms"       = ["devops", "secops"],
    "thomas.black"       = ["bizops"],
    "tiffanyj.andrews"   = ["analytics"],
    "timothy.spencer"    = ["devops", "secops"],
    "zach.margolis"      = ["appdev", "apponcall"],
  }
}
