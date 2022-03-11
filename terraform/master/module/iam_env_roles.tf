module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=a6261020a94b77b08eedf92a068832f21723f7a2"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
