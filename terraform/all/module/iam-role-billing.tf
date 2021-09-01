module "billing-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=af60fa023799d7f14c9f0f78ebaeb0bb6b2d7b5c"

  role_name                = "BillingReadOnly"
  enabled                  = lookup(
                                merge(local.role_enabled_defaults,var.account_roles_map),
                                "iam_billing_enabled",
                                lookup(local.role_enabled_defaults,"iam_billing_enabled")
                              )
  master_assumerole_policy = local.master_assumerole_policy
  custom_policy_arns       = local.custom_policy_arns

  iam_policies = [
    {
      policy_name        = "BillingReadOnly"
      policy_description = "Policy for reporting group read-only access to Billing ui"
      policy_document = [
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
