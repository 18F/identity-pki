module "billing-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=99eb230e7ecf64838d4eef07f730bc552d15723a"

  role_name                = "BillingReadOnly"
  enabled                  = var.iam_billing_enabled
  master_assumerole_policy = local.master_assumerole_policy
  custom_policy_arns       = local.custom_policy_arns

  iam_policies = [
    {
      policy_name        = "BillingReadOnly"
      policy_description = "Policy for reporting group read-only access to Billing ui"
      policy_document    = [
        {
          sid    = "BillingReadOnly"
          effect = "Allow"
          actions = [
            "aws-portal:ViewBilling",
          ]
          resources = [
            "*",
          ]
        },
      ]
    },
  ]
}
