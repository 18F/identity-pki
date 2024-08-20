data "aws_iam_role" "analytics" {
  name = "Analytics"
}

data "aws_iam_policy_document" "quicksight_access" {
  statement {
    sid    = "Quicksight"
    effect = "Allow"
    actions = [
      "quicksight:CreateDashboard",
      "quicksight:DescribeDashboard",
      "quicksight:ListDashboards",
      "quicksight:UpdateDashboard",
      "quicksight:DeleteDashboard",
      "quicksight:CreateAnalysis",
      "quicksight:DescribeAnalysis",
      "quicksight:ListAnalyses",
      "quicksight:UpdateAnalysis",
      "quicksight:DeleteAnalysis"
    ]
    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "redshift_user_access_analytics" {
  statement {
    sid    = "RedshiftUserAccess"
    effect = "Allow"
    actions = [
      "redshift:GetClusterCredentials",
    ]
    resources = [
      "arn:aws:redshift:us-west-2:*:cluster:*",
      "arn:aws:redshift:us-west-2:*:dbname:*/analytics",
      "arn:aws:redshift:us-west-2:*:dbuser:*/$${redshift:DbUser}"
    ]
    condition {
      test     = "StringEqualsIgnoreCase"
      variable = "aws:userid"
      values = [
        "${data.aws_iam_role.analytics.unique_id}:$${redshift:DbUser}",
      ]
    }
  }
}

resource "aws_iam_policy" "analytics_user" {
  name   = "DataWarehouseAnalyticsUser"
  policy = data.aws_iam_policy_document.analytics_user.json
}

data "aws_iam_policy_document" "analytics_user" {
  source_policy_documents = [
    data.aws_iam_policy_document.redshift_query_execution_access.json,
    data.aws_iam_policy_document.redshift_user_access_analytics.json,
    data.aws_iam_policy_document.quicksight_access.json,
    data.aws_iam_policy_document.query_editor_v2_kms_access.json,
  ]
}

resource "aws_iam_role_policy_attachment" "analytics_user" {
  role       = data.aws_iam_role.targets["Analytics"].name
  policy_arn = aws_iam_policy.analytics_user.arn
}

resource "aws_iam_role_policy_attachment" "analytics_no_sharing" {
  role       = data.aws_iam_role.targets["Analytics"].name
  policy_arn = data.aws_iam_policy.query_editor_no_sharing.arn
}

resource "aws_iam_role_policy_attachment" "analytics_read_only" {
  role       = data.aws_iam_role.targets["Analytics"].name
  policy_arn = data.aws_iam_policy.redshift_read_only.arn
}
