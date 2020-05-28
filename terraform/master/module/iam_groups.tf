# Group definitions

# AppDev
module "appdev_group" {
  source = "github.com/18F/identity-terraform//iam_assumegroup?ref=95a15c29faffffabb454881629b7a126fcad6d3c"
  #source = "../../../../identity-terraform/iam_assumegroup"

  group_name = "appdev"
  iam_group_roles = [
    {
      role_name = "PowerUser",
      account_types = [
        "Sandbox"
      ]
    },
    {
      role_name = "ReadOnly",
      account_types = [
        "Sandbox"
      ]
    }
  ]
  master_account_id = var.master_account_id
}

# AppOnCall
module "apponcall_group" {
  source = "github.com/18F/identity-terraform//iam_assumegroup?ref=95a15c29faffffabb454881629b7a126fcad6d3c"
  #source = "../../../../identity-terraform/iam_assumegroup"

  group_name = "apponcall"
  iam_group_roles = [
    {
      role_name = "PowerUser",
      account_types = [
        "Sandbox", "Prod"
      ]
    },
    {
      role_name = "ReadOnly",
      account_types = [
        "Sandbox", "Prod"
      ]
    }
  ]
  master_account_id = var.master_account_id
}

# BizOps
module "bizops_group" {
  source = "github.com/18F/identity-terraform//iam_assumegroup?ref=95a15c29faffffabb454881629b7a126fcad6d3c"
  #source = "../../../../identity-terraform/iam_assumegroup"

  group_name = "bizops"
  iam_group_roles = [
    {
      role_name = "ReportsReadOnly",
      account_types = [
        "Sandbox", "Prod"
      ]
    },
  ]
  master_account_id = var.master_account_id
}

# DevOps
module "devops_group" {
  source = "github.com/18F/identity-terraform//iam_assumegroup?ref=95a15c29faffffabb454881629b7a126fcad6d3c"
  #source = "../../../../identity-terraform/iam_assumegroup"

  group_name = "devops"
  iam_group_roles = [
    {
      role_name = "FullAdministrator",
      account_types = [
        "Prod", "Sandbox", "Master"
      ]
    },
    {
      role_name = "ReadOnly",
      account_types = [
        "Prod", "Sandbox"
      ]
    },
    {
      role_name = "KMSAdministrator",
      account_types = [
        "Sandbox"
      ]
    }
  ]
  master_account_id = var.master_account_id
}

# FinOps
module "finops_group" {
  #source = "github.com/18F/identity-terraform//iam_assumegroup?ref=95a15c29faffffabb454881629b7a126fcad6d3c"
  source = "../../../../identity-terraform/iam_assumegroup"

  group_name = "finops"
  iam_group_roles = [
    {
      role_name = "BillingReadOnly",
      account_types = [
        "Sandbox", "Prod"
      ]
    },
  ]
  master_account_id = var.master_account_id
}

# SecOps
module "secops_group" {
  source = "github.com/18F/identity-terraform//iam_assumegroup?ref=95a15c29faffffabb454881629b7a126fcad6d3c"
  #source = "../../../../identity-terraform/iam_assumegroup"

  group_name = "secops"
  iam_group_roles = [
    {
      role_name = "FullAdministrator",
      account_types = [
        "Sandbox", "Prod", "Master"
      ]
    },
    {
      role_name = "ReadOnly",
      account_types = [
        "Sandbox", "Prod"
      ]
    },
    {
      role_name = "KMSAdministrator",
      account_types = [
        "Sandbox"
      ]
    }
  ]
  master_account_id = var.master_account_id
}

# SOC
module "soc_group" {
  source = "github.com/18F/identity-terraform//iam_assumegroup?ref=95a15c29faffffabb454881629b7a126fcad6d3c"
  #source = "../../../../identity-terraform/iam_assumegroup"

  group_name = "soc"
  group_members = [
  ]
  iam_group_roles = [
    {
      role_name = "SOCAdministrator",
      account_types = [
        "Sandbox", "Prod", "Master"
      ]
    }
  ]
  master_account_id = var.master_account_id
}

# KeyMasters  - Not in team.yml
module "keymasters_group" {
  source = "github.com/18F/identity-terraform//iam_assumegroup?ref=95a15c29faffffabb454881629b7a126fcad6d3c"
  #source = "../../../../identity-terraform/iam_assumegroup"

  group_name = "keymasters"
  iam_group_roles = [
    {
      role_name = "KMSAdministrator",
      account_types = [
        "Prod"
      ]
    }
  ]
  master_account_id = var.master_account_id
}
