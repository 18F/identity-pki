data "aws_iam_policy_document" "appdev" {
  count  = var.iam_appdev_enabled ? 1 : 0
  statement {
    sid    = "Autoscaling"
    effect = "Allow"
    actions = [
      "autoscaling:*",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid    = "CloudWatch"
    effect = "Allow"
    actions = [
      "cloudwatch:Describe*",
      "cloudwatch:List*",
      "cloudwatch:Get*",
      "events:List*",
      "events:Describe*",
      "events:TestEventPattern",
      "logs:Describe*",
      "logs:List*",
      "logs:Filter*",
      "logs:Get*",
      "logs:StartQuery",
      "logs:StopQuery",
      "logs:TestMetricFilter",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid    = "SNS"
    effect = "Allow"
    actions = [
      "sns:List*",
      "sns:CheckIfPhoneNumberIsOptedOut",
      "sns:Get*",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid    = "KMS"
    effect = "Allow"
    actions = [
      "kms:List*",
      "kms:DescribeKey",
      "kms:Get*",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid    = "IAM"
    effect = "Allow"
    actions = [
      "iam:Get*",
      "iam:List*",
      "iam:Simulate*",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid    = "CloudFront"
    effect = "Allow"
    actions = [
      "cloudfront:ListTagsForResource",
      "cloudfront:TagResource",
      "cloudfront:UpdateDistribution",
      "cloudfront:CreateInvalidation",
      "cloudfront:GetDistribution",
      "cloudfront:ListDistributions",
      "cloudfront:ListInvalidations",
      "cloudfront:ListFieldLevelEncryptionConfigs",
      "cloudfront:LisStreamingDistributions",
      "cloudfront:CreateDistribution",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid    = "Dynamodb"
    effect = "Allow"
    actions = [
      "dynamodb:List*",
      "dynamodb:BatchGet*",
      "dynamodb:ConditionCheckItem",
      "dynamodb:Describe*",
      "dynamodb:Get*",
      "dynamodb:Query",
      "dynamodb:Scan",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid    = "RDS"
    effect = "Allow"
    actions = [
      "rds:Describe*",
      "rds:List*",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid    = "Route53"
    effect = "Allow"
    actions = [
      "route53:Get*",
      "route53:List*",
      "route53:TestDNSAnswer",
      "route53resolver:List*",
      "route53resolver:Get*",
      "route53domains:List*",
      "route53domains:CheckDomainAvailability",
      "route53domains:ViewBilling",
      "route53domains:Get*",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid    = "STS"
    effect = "Allow"
    actions = [
      "sts:DecodeAuthorizationMessage",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid    = "Lambda"
    effect = "Allow"
    actions = [
      "lambda:*",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid    = "ACM"
    effect = "Allow"
    actions = [
      "acm:DescribeCertificate",
      "acm:ListCertificates",
      "acm:ListTagsForCertificate",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid    = "CloudTrail"
    effect = "Allow"
    actions = [
      "cloudtrail:DescribeTrails",
      "cloudtrail:GetTrailStatus",
      "cloudtrail:ListTags",
      "cloudtrail:LookupEvents",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid    = "EC2"
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "ec2:Get*",
      "ec2:AssignPrivateIpAddresses",
      "ec2:CreateSnapshot",
      "ec2:GetConsoleScreenshot",
      "ec2:GetConsoleOutput",
      "ec2:RunInstances",
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:TerminateInstances",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid    = "ElasticCache"
    effect = "Allow"
    actions = [
      "elasticache:Describe*",
      "elasticache:List*",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid    = "ELB"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
      "elasticloadbalancing:AttachLoadBalancerToSubnets",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:ConfigureHealthCheck",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateLoadBalancerListeners",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:SetWebACL",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid    = "S3"
    effect = "Allow"
    actions = [
      "s3:List*",
      "s3:Get*",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid    = "SES"
    effect = "Allow"
    actions = [
      "ses:List*",
      "ses:Get*",
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role" "appdev" {
  count                = var.iam_appdev_enabled ? 1 : 0
  
  name                 = "Appdev"
  assume_role_policy   = data.aws_iam_policy_document.master_account_assumerole.json
  path                 = "/"
  max_session_duration = 43200 #seconds
}

resource "aws_iam_policy" "appdev" {
  count  = var.iam_appdev_enabled ? 1 : 0

  name        = "AppDev1"
  path        = "/"
  description = "Policy for appdev with MFA"
  policy      = data.aws_iam_policy_document.appdev[0].json
}

resource "aws_iam_role_policy_attachment" "appdev" {
  count  = var.iam_appdev_enabled ? 1 : 0
  
  role       = aws_iam_role.appdev[0].name
  policy_arn = aws_iam_policy.appdev[0].arn
}

resource "aws_iam_role_policy_attachment" "appdev_rds_delete_prevent" {
  count  = var.iam_appdev_enabled ? 1 : 0
  
  role       = aws_iam_role.appdev[0].name
  policy_arn = aws_iam_policy.rds_delete_prevent.arn
}

resource "aws_iam_role_policy_attachment" "appdev_region_restriction" {
  count  = var.iam_appdev_enabled ? 1 : 0
  
  role       = aws_iam_role.appdev[0].name
  policy_arn = aws_iam_policy.region_restriction.arn
}
