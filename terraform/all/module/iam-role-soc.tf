module "socadmin-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=5aa7231e4a3a91a9f4869311fbbaada99a72062b"
  #source = "../../../../identity-terraform/iam_assumerole"

  role_name                       = "SOCAdministrator"
  enabled                         = contains(local.enabled_roles, "iam_socadmin_enabled")
  master_assumerole_policy        = data.aws_iam_policy_document.master_account_assumerole.json
  custom_iam_policies             = var.dnssec_zone_exists ? [data.aws_iam_policy.dnssec_disable_prevent[0].name] : []
  permissions_boundary_policy_arn = aws_iam_policy.permissions_boundary.arn

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
            "detective:*",
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
            "inspector2:*",
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
            "arn:aws:s3:::login-gov-athena-queries-*",
            "arn:aws:s3:::login-gov-athena-queries-*/*",
            "arn:aws:s3:::aws-athena-query-results-${data.aws_caller_identity.current.account_id}-${var.region}",
            "arn:aws:s3:::aws-athena-query-results-${data.aws_caller_identity.current.account_id}-${var.region}/*"
          ]
        }
      ]
    }
  ]
}
