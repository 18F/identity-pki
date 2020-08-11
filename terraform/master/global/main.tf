provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["340731855345"] # require login-master
  profile             = "login-master"

  version = "~> 2.70.0"
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
      { "Analytics"         = [ "Sandbox", "Prod", "Analytics" ] }
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
      { "FullAdministrator" = [ "Prod", "Sandbox", "Master", "Analytics" ] },
      { "ReadOnly"          = [ "Prod", "Sandbox" ] },
      { "Terraform"         = [ "Prod", "Sandbox", "Master" ] },
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

  auditor_accounts = {
    master        = "340731855345" # Include master for testing
    techportfolio = "133032889584" # TTS Tech Portfolio
  }

  # User to group mappings - Groups defined in ../module/iam_groups.tf
  user_map = {
    "aaron.chapman"      = ["appdev", "apponcall"],
    "akhlaq.khan"        = ["analytics", "finops", "bizops"],
    "alex.mathews"       = ["appdev"],
    "amit.freeman"       = ["devops"],
    "amos.stone"         = ["analytics"],
    "andrew.duthie"      = ["appdev"],
    "anthony.martini"    = ["secops"],
    "brett.mcparland"    = ["secops", "soc"],
    "brian.crissup"      = ["devops", "keymasters"],
    "christopher.billas" = ["bizops", "finops"],
    "clinton.troxel"     = ["appdev"],
    "douglas.price"      = ["appdev", "apponcall", "bizops"],
    "jeff.shultz"        = ["analytics"],
    "john.yuda"          = ["analytics"],
    "jonathan.hooper"    = ["appdev", "apponcall", "keymasters"],
    "jonathan.pirro"     = ["devops"],
    "julia.elman"        = ["analytics"],
    "justin.grevich"     = ["devops"],
    "likhitha.patha"     = ["bizops"],
    "michael.antiporta"  = ["analytics"],
    "mitchell.henke"     = ["appdev"],
    "mossadeq.zia"       = ["devops", "secops", "keymasters"],
    "phil.lam"           = ["analytics"],
    "paul.hirsch"        = ["devops"],
    "shade.jenifer"      = ["appdev", "apponcall"]
    "silke.dannemann"    = ["bizops"],
    "steve.urciuoli"     = ["appdev", "apponcall", "keymasters"],
    "steven.harms"       = ["devops", "secops"],
    "thomas.black"       = ["bizops"],
    "timothy.spencer"    = ["devops", "secops"],
    "zach.margolis"      = ["appdev", "apponcall"],
  }
}
