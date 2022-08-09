module "analytics-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=5d344d205dd09eb85d5de1ff1081c4a598afe433"

  role_name = "Analytics"
  enabled = lookup(
    merge(local.role_enabled_defaults, var.account_roles_map),
    "iam_analytics_enabled",
    lookup(local.role_enabled_defaults, "iam_analytics_enabled")
  )
  master_assumerole_policy = data.aws_iam_policy_document.master_account_assumerole.json
  custom_policy_arns = compact([
    aws_iam_policy.rds_delete_prevent.arn,
    aws_iam_policy.region_restriction.arn,
    var.dnssec_zone_exists ? data.aws_iam_policy.dnssec_disable_prevent[0].arn : "",
  ])

  iam_policies = [
    {
      policy_name        = "Analytics"
      policy_description = "Policy for Analytics user with MFA"
      policy_document = [
        {
          sid    = "AllBucketsList"
          effect = "Allow"
          actions = [
            "s3:ListAllMyBuckets"
          ]
          resources = [
            "arn:aws:s3:::*"
          ]
        },
        {
          sid    = "AthenaAccess"
          effect = "Allow"
          actions = [
            "athena:List*",
            "athena:BatchGet*",
            "athena:Get*",
            "athena:StartQueryExecution",
            "athena:StopQueryExecution",
            "athena:CreateNamedQuery",
            "athena:CreatePreparedStatement",
            "athena:DeleteNamedQuery",
            "athena:DeletePreparedStatement",
            "athena:UpdateNamedQuery",
            "athena:UpdatePreparedStatement",
            "glue:BatchGetPartition",
            "glue:GetDatabase",
            "glue:GetDatabases",
            "glue:GetPartition",
            "glue:GetPartitions",
            "glue:GetTable",
            "glue:GetTables",
          ]
          resources = [
            "*"
          ]
        },
        {
          sid    = "AthenaBucketAccess"
          effect = "Allow"
          actions = [
            "s3:GetObject",
            "s3:HeadBucket",
            "s3:List*",
            "s3:PutObject",
          ]
          resources = [
            "arn:aws:s3:::login-gov-athena-query-results-*",
            "arn:aws:s3:::login-gov-athena-query-results-*/*"
          ]
        },
        {
          sid    = "ReportsBucketAccess"
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
          sid    = "PubdataBucketAccess"
          effect = "Allow"
          actions = [
            "s3:GetObject",
            "s3:HeadBucket",
            "s3:List*",
            "s3:PutObject",
          ]
          resources = [
            "arn:aws:s3:::login-gov-pubdata-*",
            "arn:aws:s3:::login-gov-pubdata-*/*"
          ]
        },
        {
          sid    = "CloudTrailBucketAccess"
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
          sid    = "CloudTrailReadAccess"
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
          sid    = "CloudWatchReadAccess"
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
