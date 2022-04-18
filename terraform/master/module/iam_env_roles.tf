module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=44f3800286f84d83995c8ef63d7f8d19d85a0204"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
