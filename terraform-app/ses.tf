# Roles and policies relevant to Amazon Simple Email Service
#
# See https://docs.aws.amazon.com/ses/latest/DeveloperGuide/control-user-access.html
#
# Refer to top comment in secrets.tf  to understand how IAM roles, policies, 
# and instance profile work. 


#Allow SES to send emails from the idp hosts
data "aws_iam_policy_document" "ses_email_role_policy" {
  statement {
    sid = "AllowSendEmail"
    effect = "Allow"
    actions = [
      "ses:SendRawEmail",
      "ses:SendEmail"
    ]
    resources = [
      "arn:aws:ec2:::*"
    ]
  }
}

