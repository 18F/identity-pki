module "analytics-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=0eedb22803b1d68fb0c0dd7a0d325cb1a9bb69ba"

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

data "aws_iam_policy_document" "analytics_role_key_access" {
  statement {
    sid = "AthenaKMSKeyAccess"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      "*"
    ]
    condition {
        test     = "ForAnyValue:StringLike"
        variable = "kms:ResourceAliases"

        values = [
          "alias/*-kms-s3-log-cache-bucket",
        ]
      }
  }
}

resource "aws_iam_policy" "analytics_role_key_access" {
  name        = "AthenaKMSKeyAccess"
  description = "Give users access to the keys used in Athena"
  policy      = data.aws_iam_policy_document.analytics_role_key_access.json
}

resource "aws_iam_role_policy_attachment" "analytics_role_key_access" {
  role       = module.analytics-assumerole.iam_assumable_role[0].name
  policy_arn = aws_iam_policy.analytics_role_key_access.arn
}
