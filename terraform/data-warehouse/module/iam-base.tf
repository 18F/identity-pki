resource "aws_iam_role" "flow_role" {
  name               = "${var.env_name}_flow_role"
  description        = "Allows VPC Flow Logs to publish logs to AWS CloudWatch."
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "flow_policy" {
  name   = "${var.env_name}_flow_policy"
  role   = aws_iam_role.flow_role.id
  policy = data.aws_iam_policy_document.flow_policy.json
}

data "aws_iam_policy_document" "flow_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = [
      aws_cloudwatch_log_group.flow_log_group.arn,
      "${aws_cloudwatch_log_group.flow_log_group.arn}:*"
    ]
  }
}
