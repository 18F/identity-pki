# Role assumed by idp role in main account for delivering SMS messages and
# voice calls.
resource "aws_iam_role" "idp-pinpoint" {
  name = "idp-pinpoint"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {"AWS": "arn:aws:iam::${var.main_account_id}:root"}
    }
  ]
}
EOF

}

# Allow sending SMS/Voice messages with Pinpoint
# Allow managing opt-in/opt-out of phone numbers
resource "aws_iam_role_policy" "idp-pinpoint-send" {
  name   = "idp-pinpoint-send"
  role   = aws_iam_role.idp-pinpoint.id
  policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "mobiletargeting:PhoneNumberValidate",
                "mobiletargeting:SendMessages",
                "mobiletargeting:SendUsersMessages",
                "sms-voice:SendVoiceMessage",
                "sns:CheckIfPhoneNumberIsOptedOut",
                "sns:ListPhoneNumbersOptedOut",
                "sns:OptInPhoneNumber"
            ],
            "Resource": "*"
        }
    ]
}
EOM
}
