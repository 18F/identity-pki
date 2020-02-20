data "aws_iam_policy_document" "fulladmin" {
  statement {
    sid    = "FullAdministrator"
    effect = "Allow"
    actions = [
      "*",
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "fulladmin" {
  name        = "FullAdministrator"
  path        = "/"
  description = "Policy for full administrator"
  policy      = data.aws_iam_policy_document.fulladmin.json
}

resource "aws_iam_role" "fulladmin" {
  name                 = "FullAdministrator"
  assume_role_policy   = data.aws_iam_policy_document.master_account_assumerole.json
  path                 = "/"
  max_session_duration = 43200 #seconds
}

resource "aws_iam_role_policy_attachment" "fulladmin" {
  role       = aws_iam_role.fulladmin.name
  policy_arn = aws_iam_policy.fulladmin.arn
}

resource "aws_iam_role_policy_attachment" "fulladmin_rds_delete_prevent" {
  role       = aws_iam_role.fulladmin.name
  policy_arn = aws_iam_policy.rds_delete_prevent.arn
}

resource "aws_iam_role_policy_attachment" "fulladmin_region_restriction" {
  role       = aws_iam_role.fulladmin.name
  policy_arn = aws_iam_policy.region_restriction.arn
}
