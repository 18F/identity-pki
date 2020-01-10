resource "aws_iam_policy" "billing_ro" {
  name        = "BillingReadOnly"
  description = "Policy for reporting group read-only access to Billing ui"
  policy      = data.aws_iam_policy_document.billing_ro.json
}

data "aws_iam_policy_document" "billing_ro" {
  statement {
    sid    = "BillingReadOnly"
    effect = "Allow"
    actions = [
      "aws-portal:ViewBilling",
    ]
    resources = [
      "*",
    ]
  }
}
