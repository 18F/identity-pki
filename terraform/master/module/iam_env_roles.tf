module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=fe2fee6bc6ea80e341822ad40e3e621373497290"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
