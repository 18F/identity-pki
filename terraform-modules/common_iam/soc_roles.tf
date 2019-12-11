resource "aws_iam_role" "soc_admin" {
    name = "SOCAdministrator"
    assume_role_policy = data.aws_iam_policy_document.master_account_assumerole.json
    path = "/"
    max_session_duration = 43200 #seconds
}

resource "aws_iam_role_policy_attachment" "soc_admin" {
    role = aws_iam_role.soc_admin.name
    policy_arn = aws_iam_policy.soc_administrator.arn
}
