module "analytics-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=e7ad5ef38f724b31911248a74173e9fee3bbf045"

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
          sid    = "AthenaConsoleAccess"
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
          sid    = "AthenaKMSKeyAccess"
          effect = "Allow"
          actions = [
            "kms:Decrypt",
            "kms:DescribeKey",
            "kms:Encrypt",
            "kms:GenerateDataKey",
          ]
          resources = [
            "*"
          ]
          conditions = [
            {
              test     = "ForAnyValue:StringLike"
              variable = "kms:ResourceAliases"
              values   = ["alias/*-kms-s3-log-cache-bucket"]
            }
          ]
        },
        {
          sid    = "AthenaOutputBucketAccess"
          effect = "Allow"
          actions = [
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads",
            "s3:AbortMultipartUpload",
            "s3:PutObject",
            "s3:ListMultipartUploadParts"
          ]
          resources = [
            "arn:aws:s3:::login-gov-athena-queries-*",
            "arn:aws:s3:::login-gov-athena-queries-*/*"
          ]
        },
        {
          sid    = "AthenaSourceBucketAccess"
          effect = "Allow"
          actions = [
            "s3:GetObject",
            "s3:ListBucket"
          ]
          resources = [
            "arn:aws:s3:::login-gov-log-cache-*",
            "arn:aws:s3:::login-gov-log-cache-*/*",
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
        }
      ]
    },
  ]
}