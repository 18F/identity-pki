module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=6e0d3619b3ddf7e59eb2755a267444b526df4c9a"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
