module "reports-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=7445ae915936990bc52109087d92e5f9564f0f7c"

  role_name = "ReportsReadOnly"
  enabled = lookup(
    merge(local.role_enabled_defaults, var.account_roles_map),
    "iam_reports_enabled",
    lookup(local.role_enabled_defaults, "iam_reports_enabled")
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
      policy_name        = "ReportsReadOnly"
      policy_description = "Policy for reporting group read-only access to Reports bucket"
      policy_document = [
        {
          sid    = "RROAllBuckets"
          effect = "Allow"
          actions = [
            "s3:ListAllMyBuckets"
          ]
          resources = [
            "arn:aws:s3:::*"
          ]
        },
        {
          sid    = "RROSeeBucket"
          effect = "Allow"
          actions = [
            "s3:ListBucket"
          ]
          resources = [
            var.reports_bucket_arn
          ]
        },
        {
          sid    = "RROGetObjects"
          effect = "Allow"
          actions = [
            "s3:GetObject",
            "s3:GetAccountPublicAccessBlock",
            "s3:GetBucketEncryption",
            "s3:GetBucketPublicAccessBlock",
            "s3:GetBucketVersioning",
          ]
          resources = [
            "${var.reports_bucket_arn}/*"
          ]
        },
        {
          sid    = "RROCloudWatch"
          effect = "Allow"
          actions = [
            "application-autoscaling:DescribeScalingPolicies",
            "autoscaling:DescribePolicies",
            "autoscaling:DescribeScalingPolicies",
            "cloudwatch:DescribeAlarms",
            "cloudwatch:GetDashboard",
            "cloudwatch:ListDashboards",
            "iam:GetAccountSummary",
            "iam:ListAccountAliases",
            "logs:DescribeLogGroups",
            "logs:DescribeQueryDefinitions",
            "logs:DescribeMetricFilters",
            "logs:FilterLogEvents",
            "resource-groups:ListGroups",
            "sns:ListSubscriptions",
            "sns:ListTopics",
          ]
          resources = [
            "*"
          ]
        }
      ]
    }
  ]
}
