module "billing-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=5d344d205dd09eb85d5de1ff1081c4a598afe433"

  role_name = "BillingReadOnly"
  enabled = lookup(
    merge(local.role_enabled_defaults, var.account_roles_map),
    "iam_billing_enabled",
    lookup(local.role_enabled_defaults, "iam_billing_enabled")
  )
  master_assumerole_policy = data.aws_iam_policy_document.master_account_assumerole.json
  custom_policy_arns = compact([
    aws_iam_policy.rds_delete_prevent.arn,
    aws_iam_policy.region_restriction.arn,
    var.dnssec_zone_exists ? data.aws_iam_policy.dnssec_disable_prevent[0].arn : "",
  ])

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

### TODO: set this up and figure out enforcement in a future PR
#resource "aws_iam_role_policy" "ssm_nondoc_deny_billing" {
#  count = sum([
#    contains(keys(var.ssm_access_map),"BillingReadOnly") ? 0 : 1,
#    length(keys(var.ssm_access_map)) == 0 ? 0 : 1
#  ]) == 2 ? 1 : 0
#  
#  name        = "BillingReadOnly-SSMNonDocDeny"
#  role        = "BillingReadOnly"
#  policy      = data.aws_iam_policy_document.ssm_nondoc_deny.json
#}
