module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=95a15c29faffffabb454881629b7a126fcad6d3c"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
