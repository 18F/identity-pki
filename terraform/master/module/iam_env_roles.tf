# TODO: change to iterative for_each design once https://github.com/hashicorp/terraform/issues/17519 is fixed

module "assume_roles_prod" {
  #source = "github.com/18F/identity-terraform//iam_masterassume?ref=7216bbba9a74eee84adf2dabae51a3d8c0d165d5"
  source = "../../../../identity-terraform/iam_masterassume"

  role_list = var.role_list
  account_type = "Prod"
  account_numbers = var.prod_aws_account_nums
}

module "assume_roles_nonprod" {
  #source = "github.com/18F/identity-terraform//iam_masterassume?ref=7216bbba9a74eee84adf2dabae51a3d8c0d165d5"
  source = "../../../../identity-terraform/iam_masterassume"

  role_list = var.role_list
  account_type = "Sandbox"
  account_numbers = var.nonprod_aws_account_nums
}

module "assume_roles_master" {
  #source = "github.com/18F/identity-terraform//iam_masterassume?ref=7216bbba9a74eee84adf2dabae51a3d8c0d165d5"
  source = "../../../../identity-terraform/iam_masterassume"

  role_list = var.role_list
  account_type = "Master"
  account_numbers = ["340731855345"]
}