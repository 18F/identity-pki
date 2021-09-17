module "socadmin-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=7e11ebe24e3a9cbc34d1413cf4d20b3d71390d5b"

  role_name = "SOCAdministrator"
  enabled = lookup(
    merge(local.role_enabled_defaults, var.account_roles_map),
    "iam_socadmin_enabled",
    lookup(local.role_enabled_defaults, "iam_socadmin_enabled")
  )
  master_assumerole_policy = local.master_assumerole_policy
  custom_policy_arns       = local.custom_policy_arns

  iam_policies = [
    {
      policy_name        = "SOCAdministrator"
      policy_description = "Policy for SOC administrators"
      policy_document = [
        {
          sid    = "SOCAdministrator"
          effect = "Allow"
          actions = [
            "access-analyzer:*",
            "athena:*",
            "cloudtrail:*",
            "cloudwatch:*",
            "config:*",
            "ec2:DescribeRegions",
            "elasticloadbalancing:*",
            "glue:*",
            "guardduty:*",
            "iam:Get*",
            "iam:List*",
            "iam:Generate*",
            "inspector:*",
            "logs:*",
            "macie:*",
            "macie2:*",
            "organizations:List*",
            "organizations:Describe*",
            "rds:Describe*",
            "rds:List*",
            "s3:HeadBucket",
            "s3:List*",
            "s3:Get*",
            "securityhub:*",
            "shield:*",
            "ssm:*",
            "sns:*",
            "trustedadvisor:*",
            "waf:*",
            "wafv2:*",
            "waf-regional:*",
          ]
          resources = [
            "*"
          ]
        },
        {
          sid    = "SOCAdministratorBuckets"
          effect = "Allow"
          actions = [
            "s3:PutObject",
            "s3:AbortMultipartUpload",
            "s3:ListBucket",
            "s3:GetObject",
            "s3:DeleteObject",
          ]

          resources = [
            "arn:aws:s3:::aws-athena-query-results-${data.aws_caller_identity.current.account_id}-${var.region}",
            "arn:aws:s3:::aws-athena-query-results-${data.aws_caller_identity.current.account_id}-${var.region}/*"
          ]
        }
      ]
    }
  ]
}
