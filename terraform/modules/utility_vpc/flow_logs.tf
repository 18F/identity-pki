resource "aws_flow_log" "main" {
  vpc_id = aws_vpc.main.id

  iam_role_arn    = aws_iam_role.flow.arn
  log_destination = aws_cloudwatch_log_group.flow.arn

  traffic_type = "ALL"
  log_format = join(" ",
    [
      "$${version}",
      "$${account-id}",
      "$${interface-id}",
      "$${srcaddr}",
      "$${dstaddr}",
      "$${srcport}",
      "$${dstport}",
      "$${protocol}",
      "$${packets}",
      "$${bytes}",
      "$${start}",
      "$${end}",
      "$${action}",
      "$${log-status}",
      "$${vpc-id}",
      "$${subnet-id}",
      "$${instance-id}",
      "$${tcp-flags}",
      "$${type}",
      "$${pkt-srcaddr}",
      "$${pkt-dstaddr}",
      "$${region}",
      "$${az-id}",
      "$${sublocation-type}",
      "$${sublocation-id}",
      "$${pkt-src-aws-service}",
      "$${pkt-dst-aws-service}",
      "$${flow-direction}",
      "$${traffic-path}"
    ]
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "flow" {
  name = "imagebuild_flow_log_group"

  retention_in_days = var.cloudwatch_retention_days
}

resource "aws_iam_role" "flow" {
  name               = "imagebuild_flow_role"
  description        = "Allows VPC Flow Logs to publish logs to AWS CloudWatch."
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assumable.json
}

data "aws_iam_policy_document" "flow_logs_assumable" {
  statement {
    sid     = "AssumeVPCFlowLogs"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "flow_policy" {
  name   = "imagebuild_flow_policy"
  role   = aws_iam_role.flow.id
  policy = data.aws_iam_policy_document.flow_policy.json
}

data "aws_iam_policy_document" "flow_policy" {
  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
  }
}

