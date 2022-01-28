module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=6d1906810f2470b0b9cd38b992ac7c8b0b82f76c"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
