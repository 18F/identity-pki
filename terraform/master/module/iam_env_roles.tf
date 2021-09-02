module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=91eadab865ca59a2998387681ca83ac401b7c352"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
