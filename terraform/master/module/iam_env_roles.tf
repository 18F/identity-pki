module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=1460720310fb16f2effa84dee3d97c19bf36bc4e"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
