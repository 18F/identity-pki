module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=d1c01411db0bce308da5942a86bd2d548d902813"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
