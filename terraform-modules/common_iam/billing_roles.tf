resource "aws_iam_role" "billing_ro" {
  name                 = "BillingReadOnly"
  assume_role_policy   = data.aws_iam_policy_document.master_account_assumerole.json
  path                 = "/"
  max_session_duration = 43200 #seconds
}

resource "aws_iam_role_policy_attachment" "billing_ro" {
  role       = aws_iam_role.billing_ro.name
  policy_arn = aws_iam_policy.billing_ro.arn
}
