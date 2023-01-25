module "billing-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=7445ae915936990bc52109087d92e5f9564f0f7c"

  role_name = "BillingReadOnly"
  enabled = lookup(
    merge(local.role_enabled_defaults, var.account_roles_map),
    "iam_billing_enabled",
    lookup(local.role_enabled_defaults, "iam_billing_enabled")
  )
  master_assumerole_policy        = data.aws_iam_policy_document.master_account_assumerole.json
  permissions_boundary_policy_arn = var.permission_boundary_policy_name != "" ? data.aws_iam_policy.permission_boundary_policy[0].arn : ""
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
