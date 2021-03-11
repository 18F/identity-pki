module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=b7491b35b076c1fb37acd3fb7631b152b0b4c10b"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
