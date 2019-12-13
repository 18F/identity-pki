resource "aws_iam_group" "reporting" {
  name = "reporting"
}

resource "aws_iam_group_membership" "reporting_membership" {
  name = "reporting_membership"
  users = [
    aws_iam_user.douglas_price.name,
    aws_iam_user.jennifer_wagner.name,
    aws_iam_user.karla_rodriguez.name,
    aws_iam_user.likhitha_patha.name,
    aws_iam_user.thomas_black.name,
  ]
  group = aws_iam_group.reporting.name
}

resource "aws_iam_group_policy_attachment" "sandbox_reporting_readonly" {
  group      = aws_iam_group.reporting.name
  policy_arn = aws_iam_policy.sandbox_assume_reporting_ro.arn
}

resource "aws_iam_group_policy_attachment" "production_reporting_readonly" {
  group      = aws_iam_group.reporting.name
  policy_arn = aws_iam_policy.production_assume_reporting_ro.arn
}

