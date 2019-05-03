locals {
    password_length = 32
}
data "aws_caller_identity" "current" {}

module "iam_account" {
    source = "terraform-aws-modules/iam/aws//modules/iam-account"
    account_alias = "18f-identity-master"

    allow_users_to_change_password = true
    create_account_password_policy = true
    max_password_age = 90
    minimum_password_length = "${local.password_length}"
    password_reuse_prevention = true
    require_lowercase_characters = true
    require_numbers = true
    require_symbols = true
    require_uppercase_characters = true
}

