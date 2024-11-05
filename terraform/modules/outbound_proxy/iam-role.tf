data "aws_iam_policy_document" "obproxy_assume" {
  statement {
    sid = "allowVPC"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "obproxy" {
  count       = var.external_role == "" ? 1 : 0
  name_prefix = var.use_prefix ? "${var.env_name}_obproxy_iam_role" : null
  name        = var.use_prefix ? null : "${var.env_name}_obproxy_iam_role"

  assume_role_policy = data.aws_iam_policy_document.obproxy_assume.json
}

data "aws_iam_policy_document" "obproxy_auto_eip" {
  statement {
    sid    = "AllowEIPDescribeAndAssociate"
    effect = "Allow"
    actions = [
      "ec2:DescribeAddresses",
      "ec2:AssociateAddress"
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "obproxy_certificates" {
  statement {
    sid    = "AllowCertificatesBucketIntegrationTest"
    effect = "Allow"
    actions = [
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::login-gov.internal-certs.${data.aws_caller_identity.current.account_id}-${var.region}/${var.env_name}/",
      "arn:aws:s3:::login-gov.internal-certs.${data.aws_caller_identity.current.account_id}-${var.region}/${var.env_name}/*"
    ]
  }
}

data "aws_iam_policy_document" "obproxy_cloudwatch_agent" {
  statement {
    sid    = "allowCloudWatchAgent"
    effect = "Allow"
    actions = [
      "ec2:DescribeVolumes",
      "ec2:DescribeTags",
      "cloudwatch:PutMetricData"
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "obproxy_cloudwatch_logs" {
  statement {
    sid    = "allowCloudWatch"
    effect = "Allow"
    actions = [
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
      "logs:CreateLogStream",
      "logs:CreateLogGroup"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

data "aws_iam_policy_document" "obproxy_describe_instances" {
  statement {
    sid    = "AllowDescribeInstancesIntegrationTest"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "obproxy_secrets" {
  statement {
    sid    = "AllowBucketAndObjects"
    effect = "Allow"
    actions = [
      "s3:List*",
      "s3:Get*"
    ]
    resources = [
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/common/*",
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/common/",
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/*",
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/"
    ]
  }
  statement {
    sid    = "AllowRootAndTopListing"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*",
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:delimiter"
      values = [
        "/"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values = [
        "",
        "common/",
        "${var.env_name}/"
      ]
    }
  }
  statement {
    sid    = "AllowSubListing"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*",
    ]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        "common/",
        "${var.env_name}/*"
      ]
    }
  }
  statement {
    sid    = "AllowCompleteLifecycleHook"
    effect = "Allow"
    actions = [
      "autoscaling:RecordLifecycleActionHeartbeat",
      "autoscaling:CompleteLifecycleAction"
    ]
    resources = [
      "arn:aws:autoscaling:*:*:autoScalingGroup:*:autoScalingGroupName/${var.env_name}-*"
    ]
  }
}

# allow all instances to send a dying SNS notice
data "aws_iam_policy_document" "obproxy_sns_publish_alerts" {
  statement {
    sid    = "allowSNSPublish"
    effect = "Allow"
    actions = [
      "SNS:Publish",
    ]
    resources = [
      "${var.slack_events_sns_hook_arn}"
    ]
  }
}

resource "aws_iam_role_policy" "obproxy_auto_eip" {
  count  = var.external_role == "" ? 1 : 0
  name   = "${var.env_name}-obproxy-auto-eip"
  role   = aws_iam_role.obproxy[count.index].name
  policy = data.aws_iam_policy_document.obproxy_auto_eip.json
}

resource "aws_iam_role_policy" "obproxy_certificates" {
  count  = var.external_role == "" ? 1 : 0
  name   = "${var.env_name}-obproxy-certificates"
  role   = aws_iam_role.obproxy[count.index].name
  policy = data.aws_iam_policy_document.obproxy_certificates.json
}

resource "aws_iam_role_policy" "obproxy_cloudwatch_agent" {
  count  = var.external_role == "" ? 1 : 0
  name   = "${var.env_name}-obproxy-cloudwatch-agent"
  role   = aws_iam_role.obproxy[count.index].name
  policy = data.aws_iam_policy_document.obproxy_cloudwatch_agent.json
}

resource "aws_iam_role_policy" "obproxy_cloudwatch_logs" {
  count  = var.external_role == "" ? 1 : 0
  name   = "${var.env_name}-obproxy-cloudwatch-logs"
  role   = aws_iam_role.obproxy[count.index].name
  policy = data.aws_iam_policy_document.obproxy_cloudwatch_logs.json
}

resource "aws_iam_role_policy" "obproxy_describe_instances" {
  count  = var.external_role == "" ? 1 : 0
  name   = "${var.env_name}-obproxy-describe_instances"
  role   = aws_iam_role.obproxy[count.index].name
  policy = data.aws_iam_policy_document.obproxy_describe_instances.json
}

resource "aws_iam_role_policy" "obproxy_secrets" {
  count  = var.external_role == "" ? 1 : 0
  name   = "${var.env_name}-obproxy-secrets"
  role   = aws_iam_role.obproxy[count.index].name
  policy = data.aws_iam_policy_document.obproxy_secrets.json
}

resource "aws_iam_role_policy" "obproxy_sns_publish_alerts" {
  count  = var.external_role == "" ? 1 : 0
  name   = "${var.env_name}-obproxy-sns-publish-alerts"
  role   = aws_iam_role.obproxy[count.index].name
  policy = data.aws_iam_policy_document.obproxy_sns_publish_alerts.json
}

# allow SSM access via documents / key generation + usage
resource "aws_iam_role_policy" "obproxy_ssm_access" {
  count  = var.external_role == "" ? 1 : 0
  name   = "${var.env_name}-obproxy-ssm-access"
  role   = aws_iam_role.obproxy[count.index].name
  policy = var.ssm_access_policy
}
