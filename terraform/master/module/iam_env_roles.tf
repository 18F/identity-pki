module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
