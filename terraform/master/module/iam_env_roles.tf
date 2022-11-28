module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=e7ad5ef38f724b31911248a74173e9fee3bbf045"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
