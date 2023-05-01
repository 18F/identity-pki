module "fraudops-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/iam_assumerole"

  role_name = "FraudOps"
  enabled = lookup(
    var.account_roles_map,
    "iam_fraudops_enabled",
    lookup(local.role_enabled_defaults, "iam_fraudops_enabled", false)
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
      policy_name        = "FraudOpsReadSsmParameters"
      policy_description = "Allow FraudOps to read a subset of SSM Parameters"
      policy_document = [
        {
          sid    = "ReadSsmParameters"
          effect = "Allow"
          actions = [
            "ssm:GetParameter"
          ]
          resources = [
            "arn:aws:ssm:::parameter/account/salesforce/*"
          ]
        }
      ]
    }
  ]
}
