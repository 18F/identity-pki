data "aws_iam_policy_document" "reports" {
  count = var.iam_reports_enabled ? 1 : 0
  statement {
    sid    = "ReportsReadOnly"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
    ]
    resources = [
      var.reports_bucket_arn,
      "${var.reports_bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "reports" {
  count = var.iam_reports_enabled ? 1 : 0

  name        = "ReportsReadOnly"
  description = "Policy for reporting group read-only access to reports bucket"
  policy      = data.aws_iam_policy_document.reports[0].json
}

resource "aws_iam_role" "reports" {
  count  = var.iam_reports_enabled ? 1 : 0
  name                 = "ReportsReadOnly"
  assume_role_policy   = data.aws_iam_policy_document.master_account_assumerole.json
  path                 = "/"
  max_session_duration = 43200 #seconds
}

resource "aws_iam_role_policy_attachment" "reports" {
  count = var.iam_reports_enabled ? 1 : 0

  role       = aws_iam_role.reports[0].name
  policy_arn = aws_iam_policy.reports[0].arn
}

resource "aws_iam_role_policy_attachment" "reports_rds_delete_prevent" {
  count = var.iam_reports_enabled ? 1 : 0

  role       = aws_iam_role.reports[0].name
  policy_arn = aws_iam_policy.rds_delete_prevent.arn
}

resource "aws_iam_role_policy_attachment" "reports_region_restriction" {
  count = var.iam_reports_enabled ? 1 : 0

  role       = aws_iam_role.reports[0].name
  policy_arn = aws_iam_policy.region_restriction.arn
}
