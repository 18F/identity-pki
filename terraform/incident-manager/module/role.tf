data "aws_iam_policy_document" "incident_manager_actions_lambda_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "incident_manager_actions_lambda_role" {
  name               = "incident-manager-actions-lambda-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.incident_manager_actions_lambda_policy.json
}

data "aws_iam_policy_document" "lambda_access" {
  statement {
    sid    = "CreateLogGroupAndEvents"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = flatten([for k, v in local.teams : [
      aws_cloudwatch_log_group.incident_manager_actions[k].arn,
      "${aws_cloudwatch_log_group.incident_manager_actions[k].arn}:*"
      ]
    ])
  }

  statement {
    sid    = "InvokeLambdaFromCloudWatchAlarms"
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction",
    ]

    resources = flatten([for k, v in local.teams : [
      aws_cloudwatch_log_group.incident_manager_actions[k].arn,
      "${aws_cloudwatch_log_group.incident_manager_actions[k].arn}:*"
      ]
    ])
  }

  statement {
    sid    = "SSMAccess"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm-contacts:List*",
      "ssm-contacts:DescribeEngagement",
      "ssm-contacts:DescribePage",
      "ssm-contacts:StartEngagement",
      "ssm-contacts:StopEngagement",
      "ssm-contacts:TagResource",
      "ssm-contacts:UntagResource",
      "ssm-incidents:List*",
      "ssm-incidents:CreateTimelineEvent",
      "ssm-incidents:StartIncident",
      "ssm-incidents:TagResource",
      "ssm-incidents:UpdateIncidentRecord",
      "ssm-incidents:UpdateRelatedItems",
      "ssm-incidents:UpdateReplicationSet",
      "ssm-incidents:UpdateResponsePlan",
      "ssm-incidents:UpdateTimelineEvent",
      "ssm-incidents:UntagResource"
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "incident_manager_actions_lambda_access" {
  role   = aws_iam_role.incident_manager_actions_lambda_role.name
  policy = data.aws_iam_policy_document.lambda_access.json

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "incident_manager_actions_lambda_insights" {
  role       = aws_iam_role.incident_manager_actions_lambda_role.name
  policy_arn = module.lambda_insights.iam_policy_arn

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "incident_manager_shift_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "incident_manager_shift" {
  name               = "incident-manager-shift-lambda-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.incident_manager_shift_assume.json
}

data "aws_iam_policy_document" "incident_manager_shift" {
  statement {
    sid    = "CreateLogGroupAndEvents"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      aws_cloudwatch_log_group.incident_manager_shift.arn,
      "${aws_cloudwatch_log_group.incident_manager_shift.arn}:*"
    ]
  }

  statement {
    sid    = "SSMAccess"
    effect = "Allow"
    actions = [
      "ssm-contacts:List*"
    ]

    resources = [
      "*",
    ]
  }
  statement {
    sid    = "SNSPublish"
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]

    resources = [
      var.slack_notification_arn,
    ]
  }

}

resource "aws_iam_role_policy" "incident_manager_shift" {
  role   = aws_iam_role.incident_manager_shift.name
  policy = data.aws_iam_policy_document.incident_manager_shift.json

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "incident_manager_shift_insights" {
  role       = aws_iam_role.incident_manager_shift.name
  policy_arn = module.lambda_insights.iam_policy_arn

  lifecycle {
    create_before_destroy = true
  }
}



