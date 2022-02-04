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

locals {
  users_yaml = yamldecode(file("${path.module}/users.yaml"))
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
      "217680906704"  # login-tooling-prod
    ],
    "Sandbox" = [
      "894947205914", # login-sandbox
      "035466892286", # login-sms-sandbox
      "138431511372", # login-secops-dev
      "034795980528", # login-tooling
      "917793222841"  # login-alpha
    ],
    "Analytics" = [
      "461353137281" # login-analytics
    ]
  }

  group_role_map = {
    "appdev" = [
      { "PowerUser" = ["Sandbox"] },
      { "ReadOnly" = ["Sandbox"] },
      { "Terraform" = ["Sandbox"] }
    ],
    "analytics" = [
      { "Analytics" = ["Sandbox", "Prod"] }
    ],
    "apponcall" = [
      { "PowerUser" = ["Sandbox", "Prod"] },
      { "ReadOnly" = ["Sandbox", "Prod"] },
      { "Terraform" = ["Sandbox"] }
    ],
    "bizops" = [
      { "ReportsReadOnly" = ["Sandbox", "Prod"] }
    ],
    "devops" = [
      { "FullAdministrator" = ["Sandbox", "Prod", "Master", "Analytics"] },
      { "ReadOnly" = ["Sandbox", "Prod"] },
      { "Terraform" = ["Sandbox", "Prod", "Master"] },
      { "KMSAdministrator" = ["Sandbox", "Analytics"] }
    ],
    "devopsnonprod" = [
      { "FullAdministrator" = ["Sandbox"] },
      { "Terraform" = ["Sandbox"] }
    ],
    "finops" = [
      { "BillingReadOnly" = ["Sandbox", "Prod"] }
    ],
    "secops" = [
      { "FullAdministrator" = ["Sandbox", "Prod", "Master"] },
      { "ReadOnly" = ["Sandbox", "Prod"] },
      { "KMSAdministrator" = ["Sandbox"] }
    ],
    "secopsnonprod" = [
      { "FullAdministrator" = ["Sandbox"] },
      { "ReadOnly" = ["Sandbox"] },
      { "KMSAdministrator" = ["Sandbox"] }
    ],
    "soc" = [
      { "Auditor" = ["Sandbox", "Prod", "Master", "Analytics"] },
      { "ReadOnly" = ["Sandbox", "Prod", "Master", "Analytics"] },
      { "SOCAdministrator" = ["Sandbox", "Prod", "Master", "Analytics"] }
    ],
    "socreadonly" = [
      { "ReadOnly" = ["Sandbox", "Prod", "Master", "Analytics"] },
      { "Terraform" = ["Sandbox"] }
    ],
    "keymasters" = [
      { "KMSAdministrator" = ["Prod"] }
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
  user_map = local.users_yaml.users
}
