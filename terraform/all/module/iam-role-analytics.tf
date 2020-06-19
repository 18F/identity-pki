module "analytics-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=master"

  role_name                = "Analytics"
  enabled                  = lookup(
                                merge(local.role_enabled_defaults,var.account_roles_map),
                                "iam_analytics_enabled",
                                lookup(local.role_enabled_defaults,"iam_analytics_enabled")
                              )
  master_assumerole_policy = local.master_assumerole_policy
  custom_policy_arns       = local.custom_policy_arns

  iam_policies = [
    {
      policy_name        = "Analytics"
      policy_description = "Policy for Analytics user with MFA"
      policy_document = [
        {
          sid = "ReportsBucketAccess"
          effect = "Allow"
          actions = [
            "s3:GetObject",
            "s3:HeadBucket",
            "s3:List*",
            "s3:PutObject",
          ]
          resources = [
            "arn:aws:s3:::login-gov.reports.*",
            "arn:aws:s3:::login-gov.reports.*/*"
          ]
        },
        {
          sid = "CloudTrailBucketAccess"
          effect = "Allow"
          actions = [
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:HeadBucket",
            "s3:List*",
          ]
          resources = [
            "arn:aws:s3:::login-gov-cloudtrail-*",
            "arn:aws:s3:::login-gov-cloudtrail-*/*"
          ]
        },
        {
          sid = "CloudTrailReadAccess"
          effect = "Allow"
          actions = [
            "cloudtrail:DescribeTrails",
            "cloudtrail:GetEventSelectors",
            "cloudtrail:GetInsightSelectors",
            "cloudtrail:GetTrail",
            "cloudtrail:GetTrailStatus",
            "cloudtrail:ListPublicKeys",
            "cloudtrail:ListTags",
            "cloudtrail:ListTrails",
            "cloudtrail:LookupEvents",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid = "CloudWatchReadAccess"
          effect = "Allow"
          actions = [
            "cloudwatch:Describe*",
            "cloudwatch:List*",
            "cloudwatch:Get*",
            "cloudwatch:PutDashboard",
            "events:List*",
            "logs:Describe*",
            "logs:FilterLogEvents",
            "logs:Get*",
            "logs:ListTagsLogGroup",
            "logs:StartQuery",
            "logs:StopQuery",
            "resource-groups:ListGroups",
            "sns:ListSubscriptions",
            "sns:ListTopics",
          ]
          resources = [
            "*",
          ]
        }
      ]
    },
  ]
}
