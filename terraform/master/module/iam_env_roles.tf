module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=7e11ebe24e3a9cbc34d1413cf4d20b3d71390d5b"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
