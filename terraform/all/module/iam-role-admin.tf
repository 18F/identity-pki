module "fulladmin-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=8f0abe0e3708e2c1ef1c1653ae2b57b378bf8dbf"

  role_name                = "FullAdministrator"
  master_assumerole_policy = local.master_assumerole_policy
  custom_policy_arns       = local.custom_policy_arns

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
