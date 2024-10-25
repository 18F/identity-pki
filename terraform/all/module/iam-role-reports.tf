module "reports-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=995040426241ec92a1eccb391d32574ad5fc41be"
  #source = "../../../../identity-terraform/iam_assumerole"

  role_name                       = "ReportsReadOnly"
  enabled                         = contains(local.enabled_roles, "iam_reports_enabled")
  master_assumerole_policy        = data.aws_iam_policy_document.master_account_assumerole.json
  custom_iam_policies             = var.dnssec_zone_exists ? [data.aws_iam_policy.dnssec_disable_prevent[0].name] : []
  permissions_boundary_policy_arn = aws_iam_policy.permissions_boundary.arn

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
