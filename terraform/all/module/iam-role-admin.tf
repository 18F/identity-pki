module "fulladmin-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=91eadab865ca59a2998387681ca83ac401b7c352"

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
