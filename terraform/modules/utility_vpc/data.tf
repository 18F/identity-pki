data "aws_iam_account_alias" "current" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_eip" "main" {
  public_ip = var.image_build_nat_eip
}
