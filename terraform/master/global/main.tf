provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["340731855345"] # require login-master
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
      "217680906704", # login-tooling-prod
      "461353137281"  # login-analytics - In-ATO so included in Prod list
    ],
    "Sandbox" = [
      "894947205914", # login-sandbox
      "035466892286", # login-sms-sandbox
      "138431511372", # login-secops-dev
      "034795980528", # login-tooling-sandbox
      "917793222841"  # login-alpha
    ]
  }

  group_role_map = {
    "analytics" = [
      { "Analytics" = ["Sandbox", "Prod"] }
    ],
    "appdev" = [
      { "Analytics" = ["Sandbox", "Prod"] },
      { "PowerUser" = ["Sandbox"] },
      { "ReadOnly" = ["Sandbox"] },
      { "Terraform" = ["Sandbox"] }
    ],
    "apponcall" = [
      { "Analytics" = ["Sandbox", "Prod"] },
      { "PowerUser" = ["Sandbox", "Prod"] },
      { "ReadOnly" = ["Sandbox", "Prod"] },
      { "Terraform" = ["Sandbox"] }
    ],
    "bizops" = [
      { "Analytics" = ["Sandbox", "Prod"] },
      { "ReportsReadOnly" = ["Sandbox", "Prod"] }
    ],
    "devops" = [
      { "Analytics" = ["Sandbox", "Prod"] },
      { "FullAdministrator" = ["Sandbox", "Prod", "Master"] },
      { "ReadOnly" = ["Sandbox", "Prod"] },
      { "Terraform" = ["Sandbox", "Prod", "Master"] },
      { "KMSAdministrator" = ["Sandbox"] }
    ],
    "devopsnonprod" = [
      { "Analytics" = ["Sandbox", "Prod"] },
      { "FullAdministrator" = ["Sandbox"] },
      { "Terraform" = ["Sandbox"] }
    ],
    "escrowread" = [
      { "EscrowRead" = ["Sandbox"] }
    ]
    "finops" = [
      { "Analytics" = ["Sandbox", "Prod"] },
      { "BillingReadOnly" = ["Sandbox", "Prod"] },
      { "ReportsReadOnly" = ["Sandbox", "Prod"] }
    ],
    "fraudops" = [
#      { "Analytics" = ["Sandbox", "Prod"] },
#      { "FraudOps" = ["Sandbox", "Prod"] }
       { "Analytics" = ["Sandbox"] },
       { "FraudOps" = ["Sandbox"] }
    ],
    "secops" = [
      { "Analytics" = ["Sandbox", "Prod"] },
      { "FullAdministrator" = ["Sandbox", "Prod", "Master"] },
      { "ReadOnly" = ["Sandbox", "Prod"] },
      { "Terraform" = ["Sandbox", "Prod"] },
      { "KMSAdministrator" = ["Sandbox"] }
    ],
    "secopsnonprod" = [
      { "Analytics" = ["Sandbox", "Prod"] },
      { "FullAdministrator" = ["Sandbox"] },
      { "ReadOnly" = ["Sandbox"] },
      { "Terraform" = ["Sandbox"] },
      { "KMSAdministrator" = ["Sandbox"] }
    ],
    "soc" = [
      { "Auditor" = ["Sandbox", "Prod", "Master"] },
      { "ReadOnly" = ["Sandbox", "Prod", "Master"] },
      { "SOCAdministrator" = ["Sandbox", "Prod", "Master"] }
    ],
    "socreadonly" = [
      { "ReadOnly" = ["Sandbox", "Prod", "Master"] },
      { "Terraform" = ["Sandbox"] }
    ],
    "supporteng" = [
      { "Analytics" = ["Sandbox", "Prod"] },
      { "SupportEngineer" = ["Sandbox", "Prod"] }
    ],
    "keymasters" = [
      { "KMSAdministrator" = ["Sandbox", "Prod"] }
    ]
  }

  role_list = [
    "Analytics",
    "Auditor",
    "BillingReadOnly",
    "EscrowRead",
    "FullAdministrator",
    "PowerUser",
    "ReadOnly",
    "Terraform",
    "ReportsReadOnly",
    "KMSAdministrator",
    "SOCAdministrator",
    "SupportEngineer",
    "FraudOps",
  ]

  # User to group mappings - Groups defined in ../module/iam_groups.tf
  user_map = local.users_yaml.users
}
