locals {
  region     = "us-west-2"
  account_id = "340731855345"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id] # require login-master
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

  # This groups accounts into account types.
  # It is parsed by bin/get-aws-roles, and requires:
  # * NO TRAILING COMMAS IN LISTS!  This gets parsed as JSON
  # * A comment followed by the account alias
  aws_account_types = {
    "Master" = [
      "340731855345" # login-master
    ],
    "Organization" = [
      "121998818467" # login-org-management - Billing org account
    ],
    "Prod" = [
      "555546682965", # login-prod
      "472911866628", # login-sms-prod
      "217680906704", # login-tooling-prod
      "461353137281", # login-analytics - In-ATO so included in Prod list
      "429506220995"  # login-logarchive-prod
    ],
    "Sandbox" = [
      "894947205914", # login-sandbox
      "035466892286", # login-sms-sandbox
      "138431511372", # login-secops-dev
      "034795980528", # login-tooling-sandbox
      "487317109730", # login-analytics-sandbox
      "221972985980", # login-logarchive-sandbox
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
    "finops" = [
      { "Analytics" = ["Sandbox", "Organization", "Prod"] },
      { "BillingReadOnly" = ["Sandbox", "Organization", "Prod"] },
      { "ReportsReadOnly" = ["Sandbox", "Prod"] }
    ],
    "fraudops" = [
      { "Analytics" = ["Sandbox", "Prod"] },
      { "FraudOps" = ["Sandbox", "Prod"] }
    ],
    "eksadmin" = [
      { "EKSAdmin" = ["Sandbox", "Prod"] }
    ],
    "fraudopsnonprod" = [
      { "Analytics" = ["Sandbox"] },
      { "FraudOps" = ["Sandbox"] }
    ],
    "orgadmin" = [
      { "Analytics" = ["Organization"] },
      { "BillingReadOnly" = ["Organization"] }, # For troubleshooting/assisting finops
      { "FullAdministrator" = ["Organization"] }
    ],
    "secops" = [
      { "Analytics" = ["Sandbox", "Prod"] },
      { "FullAdministrator" = ["Sandbox", "Prod", "Master"] },
      { "ReadOnly" = ["Sandbox", "Prod", "Master"] },
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
    ],
    "secops2" = [
      { "ReadOnly" = ["Sandbox", "Prod", "Master"] }
    ],
    "prodreadonly" = [
      { "ReadOnly" = ["Sandbox", "Prod"] }
    ]
  }

  # See https://gitlab.login.gov/lg/identity-devops/-/wikis/AWS-Account-and-IAM-Configurations#aws-roles
  role_list = [
    "Analytics",
    "Auditor",
    "BillingReadOnly",
    "EKSAdmin",
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

  default_email_domain = "gsa.gov"
}

output "ses_token" {
  description = "Token for the primary verification record in Route 53."
  value       = module.main.ses_token
}

output "dkim_tokens" {
  description = <<EOM
DKIM tokens generated by SES to be created as Route53 records in login.gov HostedZone
EOM
  value       = module.main.dkim_tokens
}
