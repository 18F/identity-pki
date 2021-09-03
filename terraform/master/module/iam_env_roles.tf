module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=b68c41068a53acbb981eeb37e1eb0a36a6487ac7"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
