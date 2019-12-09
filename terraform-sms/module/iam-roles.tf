# IAM roles

# Ideally we would grant cross-account permissions to a specific source role
# rather than the whole account, but in this case we rely upon the source
# account permissions for security.
# "Principal": { "AWS": "arn:aws:iam::${var.main_account_id}:role/SomeRole" }

# Role assumed by idp role in main account for delivering SMS messages and
# voice calls. We ideally would've restricted this to the individual roles, but
# since the role names are environment-specific and we could end up adding more
# environments, it's easiest to just grant access to the whole account and rely
# on the source account's permissions.

# TODO: I couldn't figure out how to get MFA enforcement to work
# Neither of these seemed to work when the source is an EC2 IAM instance
# profile, which doesn't technically have MFA.
# "Condition": {"Bool": {"aws:MultiFactorAuthPresent": "true"}},
#
# "Effect" : "Deny",
# "Condition" : { "Bool" : { "aws:MultiFactorAuthPresent" : false } }

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
output "pinpoint_idp_role_arn" {
  value = "${aws_iam_role.idp-pinpoint.arn}"
}

# Allow sending SMS/Voice messages with Pinpoint
resource "aws_iam_role_policy" "idp-pinpoint-send" {
  name   = "idp-pinpoint-send"
  role   = "${aws_iam_role.idp-pinpoint.id}"
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
                "sms-voice:SendVoiceMessage"
            ],
            "Resource": "*"
        }
    ]
}
EOM
}


resource "aws_iam_role" "admin" {
  name = "admin"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Condition": {"Bool": {"aws:MultiFactorAuthPresent": "true"}},
      "Principal": {"AWS": "arn:aws:iam::${var.main_account_id}:root"}
    }
  ]
}
EOF
}

