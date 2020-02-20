data "aws_iam_policy_document" "billing" {
  count = var.iam_billing_enabled ? 1 : 0
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

resource "aws_iam_role" "billing" {
  count = var.iam_billing_enabled ? 1 : 0

  name                 = "BillingReadOnly"
  assume_role_policy   = data.aws_iam_policy_document.master_account_assumerole.json
  path                 = "/"
  max_session_duration = 43200 #seconds
}

resource "aws_iam_policy" "billing" {
  count = var.iam_billing_enabled ? 1 : 0

  name        = "BillingReadOnly"
  description = "Policy for reporting group read-only access to Billing ui"
  policy      = data.aws_iam_policy_document.billing[0].json
}

resource "aws_iam_role_policy_attachment" "billing" {
  count = var.iam_billing_enabled ? 1 : 0

  role       = aws_iam_role.billing[0].name
  policy_arn = aws_iam_policy.billing[0].arn
}

resource "aws_iam_role_policy_attachment" "billing_rds_delete_prevent" {
  count = var.iam_billing_enabled ? 1 : 0

  role       = aws_iam_role.billing[0].name
  policy_arn = aws_iam_policy.rds_delete_prevent.arn
}

resource "aws_iam_role_policy_attachment" "billing_region_restriction" {
  count = var.iam_billing_enabled ? 1 : 0

  role       = aws_iam_role.billing[0].name
  policy_arn = aws_iam_policy.region_restriction.arn
}
