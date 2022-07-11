module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=105ed397c16ebff2d97c762502ff73dcbda36ab9"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
