module "fulladmin-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=5aa7231e4a3a91a9f4869311fbbaada99a72062b"
  #source = "../../../../identity-terraform/iam_assumerole"

  role_name                       = "FullAdministrator"
  master_assumerole_policy        = data.aws_iam_policy_document.master_account_assumerole.json
  custom_iam_policies             = var.dnssec_zone_exists ? [data.aws_iam_policy.dnssec_disable_prevent[0].name] : []
  permissions_boundary_policy_arn = aws_iam_policy.permissions_boundary.arn

  iam_policies = [
    {
      policy_name        = "FullAdministrator"
      policy_description = "Policy for full administrator"
      policy_document = [
        {
          sid    = "FullAdministrator"
          effect = "Allow"
          actions = [
            "*",
          ]
          resources = [
            "*",
          ]
        },
      ]
    },
  ]
}
