module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=af60fa023799d7f14c9f0f78ebaeb0bb6b2d7b5c"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
