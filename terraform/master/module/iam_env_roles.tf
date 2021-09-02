module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=8f0abe0e3708e2c1ef1c1653ae2b57b378bf8dbf"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
