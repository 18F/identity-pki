locals {
  non_human_accounts = ["root", "project_21_bot"]
  users              = yamldecode(file("../../master/global/users.yaml"))
  contacts           = { for key, value in local.users["users"] : key => value if !contains(local.non_human_accounts, key) && lookup(value, "oncaller", false) }
  teams              = local.users["oncall_teams"]
  rotations          = merge([for k, v in local.users["oncall_teams"] : v["rotations"]]...)
}

data "aws_caller_identity" "current" {
}

resource "aws_ssmincidents_replication_set" "incident_manager_regions" {
  region {
    name = "us-west-2"
  }

  region {
    name = "us-east-1"
  }
}

