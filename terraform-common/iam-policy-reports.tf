resource "aws_iam_policy" "reports_ro"
{
  name = "ReportsReadOnly"
  description = "Policy for reporting group read-only access to reports bucket"
  policy = data.aws_iam_policy_document.reports_ro.json
}

data "aws_iam_policy_document" "reports_ro" {
  statement {
    sid = "ReportsReadOnly"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",]
    resources = [
       aws_s3_bucket.reports.arn
    ]
  }
}
