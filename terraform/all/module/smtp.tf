# Resources for an SES SMTP user. Requires var.smtp_user_ready to be TRUE to do
# anything. Follow the instructions below to set up an SMTP user for an account.
#
# Following are shell commands to populate the resource and bucket. Replace
# all/tooling with whatever account you're updating.
#
# aws iam create-user --user-name ses-smtp

## Run the following terraform commands to rotate keys
# bin/tf-deploy all/tooling taint 'module.main.aws_iam_access_key.ses-smtp[0]'
# bin/tf-deploy all/tooling apply

resource "aws_iam_user_policy" "ses-smtp" {
  count  = var.smtp_user_ready ? 1 : 0
  name   = "ses-smtp"
  user   = aws_iam_user.ses-smtp[0].name
  policy = data.aws_iam_policy_document.ses_email_user_policy.json
}

# Create one user per account, since each user accesses the same SMTP endpoint.
resource "aws_iam_user" "ses-smtp" {
  count = var.smtp_user_ready ? 1 : 0
  name  = "ses-smtp"
}

data "aws_iam_policy_document" "ses_email_user_policy" {
  statement {
    sid    = "AllowSendEmail"
    effect = "Allow"
    actions = [
      "ses:SendRawEmail",
      "ses:SendEmail",
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_access_key" "ses-smtp" {
  count = var.smtp_user_ready ? 1 : 0
  user  = aws_iam_user.ses-smtp[0].name
}

resource "aws_s3_object" "ses-smtp-username" {
  count   = var.smtp_user_ready ? 1 : 0
  bucket  = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key     = "common/ses_smtp_username"
  content = aws_iam_access_key.ses-smtp[0].id

  source_hash = md5(aws_iam_access_key.ses-smtp[0].id)
}

resource "aws_s3_object" "ses-smtp-password" {
  count   = var.smtp_user_ready ? 1 : 0
  bucket  = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key     = "common/ses_smtp_password"
  content = aws_iam_access_key.ses-smtp[0].ses_smtp_password_v4

  source_hash = md5(aws_iam_access_key.ses-smtp[0].ses_smtp_password_v4)
}
