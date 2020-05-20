# TODO: change to iterative for_each design once https://github.com/hashicorp/terraform/issues/17519 is fixed

module "assume_roles_prod" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=7216bbba9a74eee84adf2dabae51a3d8c0d165d5"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_types = var.role_types
  account_type = "prod"
  account_numbers = var.prod_aws_account_nums
}

output "prod_arns" {
  value = module.assume_roles_prod.role_arns
  depends_on = [module.assume_roles_prod.role_arns]
}

module "assume_roles_nonprod" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=7216bbba9a74eee84adf2dabae51a3d8c0d165d5"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_types = var.role_types
  account_type = "nonprod"
  account_numbers = var.nonprod_aws_account_nums
}

output "nonprod_arns" {
  value = module.assume_roles_nonprod.role_arns
  depends_on = [module.assume_roles_nonprod.role_arns]
}

module "assume_roles_master" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=7216bbba9a74eee84adf2dabae51a3d8c0d165d5"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_types = var.role_types
  account_type = "master"
  account_numbers = ["340731855345"]
}

output "master_arns" {
  value = module.assume_roles_master.role_arns
  depends_on = [module.assume_roles_master.role_arns]
}

