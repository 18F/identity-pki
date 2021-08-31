module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=4c89d0487c41812020dcb10e31ba9def60517b83"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
