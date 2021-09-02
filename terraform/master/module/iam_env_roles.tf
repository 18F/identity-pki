module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=9caa801ce247fa38e0ef21ef37f8ce135e8372c1"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
