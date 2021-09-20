# Resources for an SES SMTP user. Requires var.smtp_user_ready to be TRUE to do
# anything. Follow the instructions below to set up an SMTP user for an account.
#
# Following are Fish shell commands to populate the resource and bucket. Replace
# all/tooling with whatever account you're updating.
#
# aws iam create-user --user-name ses-smtp
# set KEYDATA (aws iam create-access-key --user-name ses-smtp)
# set ACCOUNTID (aws sts get-caller-identity | jq -r .Account)
# set ACCESSKEYID (echo $KEYDATA | jq -r .AccessKey.AccessKeyId)
# set SMTPPASS (bin/smtp_credentials_generate.py (echo $KEYDATA | jq -r '.AccessKey.SecretAccessKey') us-west-2)
# echo $ACCESSKEYID | aws s3 cp - "s3://login-gov.secrets."$ACCOUNTID"-us-west-2/common/ses_smtp_username" --no-guess-mime-type --content-type="text/plain" --metadata-directive="REPLACE"
# echo $SMTPPASS | aws s3 cp - "s3://login-gov.secrets."$ACCOUNTID"-us-west-2/common/ses_smtp_password" --no-guess-mime-type --content-type="text/plain" --metadata-directive="REPLACE"
# bin/tf-deploy all/tooling import 'module.main.aws_iam_user.ses-smtp[0]' ses-smtp
# bin/tf-deploy all/tooling import 'module.main.aws_iam_access_key.ses-smtp[0]' $ACCESSKEYID

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

data "aws_s3_bucket_object" "ses-smtp-username" {
  count  = var.smtp_user_ready ? 1 : 0
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/ses_smtp_username"
}

data "aws_s3_bucket_object" "ses-smtp-password" {
  count  = var.smtp_user_ready ? 1 : 0
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/ses_smtp_password"
}
