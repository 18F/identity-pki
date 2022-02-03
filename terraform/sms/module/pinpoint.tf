### pinpoint role 
resource "aws_iam_role" "pinpoint_role" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "pinpoint.${data.aws_region.current.name}.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "pinpoint_role_policy" {
  name = "pinpoint_policy"
  role = aws_iam_role.pinpoint_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Action": [
      "kinesis:PutRecords",
      "kinesis:DescribeStream"
    ],
    "Effect": "Allow",
    "Resource": [
      "${aws_kinesis_stream.pinpoint_kinesis_stream.arn}"
    ]
  }
}
EOF
}

# There aren't many resources we can manage in Terraform

resource "aws_pinpoint_app" "main" {
  name = var.pinpoint_app_name
}

resource "aws_pinpoint_sms_channel" "sms" {
  application_id = aws_pinpoint_app.main.application_id
  enabled        = true
  # sender_id - (Optional) Sender identifier of your messages.
  # short_code - (Optional) The Short Code registered with the phone provider.
}

resource "aws_pinpoint_event_stream" "stream" {
  depends_on             = [aws_kinesis_stream.pinpoint_kinesis_stream]
  application_id         = aws_pinpoint_app.main.application_id
  destination_stream_arn = aws_kinesis_stream.pinpoint_kinesis_stream.arn
  role_arn               = aws_iam_role.pinpoint_role.arn
}


output "pinpoint_app_id" {
  value = aws_pinpoint_app.main.application_id
}

