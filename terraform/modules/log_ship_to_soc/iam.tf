data "aws_iam_policy_document" "cloudwatch_logs_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cloudwatch_logs_assume_policy" {
  statement {
    effect    = "Allow"
    actions   = ["firehose:*"]
    resources = [var.soc_destination_arn]
  }
}

resource "aws_iam_role_policy" "cloudwatch_logs_policy" {
  name   = "${var.env_name}-soc_cloudwatch_logs_policy"
  role   = aws_iam_role.cloudwatch_logs_role.name
  policy = data.aws_iam_policy_document.cloudwatch_logs_assume_policy.json

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "cloudwatch_logs_role" {
  name               = "${var.env_name}-soc_cloudwatch_logs_role"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_logs_assume_role.json

  lifecycle {
    create_before_destroy = true
  }
}
