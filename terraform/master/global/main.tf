provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["340731855345"] # require login-master
  profile             = "login-master"

  version = "~> 2.29"
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
      "340731855345", # login-master
    ],
    "Prod" = [
      "555546682965", # login-prod
      "472911866628", # login-sms-prod
      "461353137281", # login-analytics-prod
      "217680906704", # login-secops-prod
    ],
    "Sandbox" = [
      "894947205914", # login-sandbox
      "035466892286", # login-sms-sandbox
      "138431511372", # login-secops-dev
      "034795980528", # login-interviews
    ],
  }
    
  role_list                = [
    "FullAdministrator",
    "PowerUser",
    "ReadOnly",
    "BillingReadOnly",
    "ReportsReadOnly",
    "KMSAdministrator",
    "SOCAdministrator",
  ]

  auditor_accounts         = {
    master        = "340731855345" # Include master for testing
    techportfolio = "133032889584" # TTS Tech Portfolio
  }
}

