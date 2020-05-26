module "assume_roles_prod" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=a0d2bcad86903c534eedbae87c4bfefb4f457f9c"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list = var.role_list
  account_type = "Prod"
  account_numbers = var.prod_aws_account_nums
}

module "assume_roles_nonprod" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=a0d2bcad86903c534eedbae87c4bfefb4f457f9c"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list = var.role_list
  account_type = "Sandbox"
  account_numbers = var.nonprod_aws_account_nums
}

module "assume_roles_master" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=a0d2bcad86903c534eedbae87c4bfefb4f457f9c"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list = var.role_list
  account_type = "Master"
  account_numbers = [var.master_account_id]
}