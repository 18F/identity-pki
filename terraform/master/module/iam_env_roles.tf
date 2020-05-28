module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=b24a37a7b4f47fb1dc4cd61267156f95c5a83ba1"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
