# Group definitions

# AppDev
module "appdev_group" {
  source = "github.com/18F/identity-terraform//iam_assumegroup?ref=b24a37a7b4f47fb1dc4cd61267156f95c5a83ba1"
  #source = "../../../../identity-terraform/iam_assumegroup"

  group_name = "appdev"
  group_members = [
    aws_iam_user.aaron_chapman.name,
    aws_iam_user.clinton_troxel.name,
    aws_iam_user.douglas_price.name,
    aws_iam_user.jonathan_hooper.name,
    aws_iam_user.steve_urciuoli.name,
    aws_iam_user.zachary_margolis.name,
  ]
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
  source = "github.com/18F/identity-terraform//iam_assumegroup?ref=b24a37a7b4f47fb1dc4cd61267156f95c5a83ba1"
  #source = "../../../../identity-terraform/iam_assumegroup"

  group_name = "apponcall"
  group_members = [
    aws_iam_user.aaron_chapman.name,
    aws_iam_user.jonathan_hooper.name,
    aws_iam_user.steve_urciuoli.name,
    aws_iam_user.zachary_margolis.name
  ]
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
  source = "github.com/18F/identity-terraform//iam_assumegroup?ref=b24a37a7b4f47fb1dc4cd61267156f95c5a83ba1"
  #source = "../../../../identity-terraform/iam_assumegroup"

  group_name = "bizops"
  group_members = [
    aws_iam_user.akhlaq_khan.name,
    aws_iam_user.christopher_billas.name,
    aws_iam_user.douglas_price.name,
    aws_iam_user.likhitha_patha.name,
    aws_iam_user.silke_dannemann.name,
    aws_iam_user.thomas_black.name,
  ]
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
  source = "github.com/18F/identity-terraform//iam_assumegroup?ref=b24a37a7b4f47fb1dc4cd61267156f95c5a83ba1"
  #source = "../../../../identity-terraform/iam_assumegroup"

  group_name = "devops"
  group_members = [
    aws_iam_user.amit_freeman.name,
    aws_iam_user.brian_crissup.name,
    aws_iam_user.jonathan_pirro.name,
    aws_iam_user.justin_grevich.name,
    aws_iam_user.mike_lloyd.name,
    aws_iam_user.mossadeq_zia.name,
    aws_iam_user.paul_hirsch.name,
    aws_iam_user.stephen_grow.name,
    aws_iam_user.steven_harms.name,
    aws_iam_user.timothy_spencer.name,
  ]
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
  source = "github.com/18F/identity-terraform//iam_assumegroup?ref=b24a37a7b4f47fb1dc4cd61267156f95c5a83ba1"
  #source = "../../../../identity-terraform/iam_assumegroup"

  group_name = "finops"
  group_members = [
    aws_iam_user.christopher_billas.name,
    aws_iam_user.akhlaq_khan.name,
  ]
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
  source = "github.com/18F/identity-terraform//iam_assumegroup?ref=b24a37a7b4f47fb1dc4cd61267156f95c5a83ba1"
  #source = "../../../../identity-terraform/iam_assumegroup"

  group_name = "secops"
  group_members = [
    aws_iam_user.brett_mcparland.name,
    aws_iam_user.mossadeq_zia.name,
    aws_iam_user.rajat_varuni.name,
    aws_iam_user.steven_harms.name,
    aws_iam_user.timothy_spencer.name,
  ]
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
  source = "github.com/18F/identity-terraform//iam_assumegroup?ref=b24a37a7b4f47fb1dc4cd61267156f95c5a83ba1"
  #source = "../../../../identity-terraform/iam_assumegroup"

  group_name = "soc"
  group_members = [
    aws_iam_user.brett_mcparland.name,
    aws_iam_user.rajat_varuni.name,
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
  source = "github.com/18F/identity-terraform//iam_assumegroup?ref=b24a37a7b4f47fb1dc4cd61267156f95c5a83ba1"
  #source = "../../../../identity-terraform/iam_assumegroup"

  group_name = "keymasters"
  group_members = [
    aws_iam_user.brian_crissup.name,
    aws_iam_user.jonathan_hooper.name,
    aws_iam_user.mossadeq_zia.name,
    aws_iam_user.rajat_varuni.name,
    aws_iam_user.steve_urciuoli.name,
  ]
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
