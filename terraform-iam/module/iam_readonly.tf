data "aws_iam_policy_document" "readonly1" {
  count  = var.iam_readonly_enabled ? 1 : 0
  statement {
    sid    = "ReadOnly1"
    effect = "Allow"
    actions = [
      "acm:Describe*",
      "acm:List*",
      "acm:Get*",
      "acm-pca:List*",
      "acm-pca:Describe*",
      "acm-pca:Get*",
      "application-autoscaling:Describe*",
      "athena:List*",
      "athena:Batch*",
      "athena:Get*",
      "autoscaling:Describe*",
      "batch:Describe*",
      "batch:List*",
      "readonly:View*",
      "budget:View*",
      "cloud9:Describe*",
      "cloud9:List*",
      "cloudformation:List*",
      "cloudformation:Describe*",
      "cloudformation:Detect*",
      "cloudformation:Get*",
      "cloudfront:Get*",
      "cloudfront:List*",
      "cloudhsm:List*",
      "cloudhsm:Describe*",
      "cloudhsm:Get*",
      "cloudtrail:Describe*",
      "cloudtrail:Get*",
      "cloudtrail:List*",
      "cloudtrail:LookupEvents",
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
      "codebuild:List*",
      "codebuild:BatchGet*",
      "codecommit:List*",
      "codecommit:BatchGet*",
      "codecommit:CancelUploadArchive",
      "codecommit:Get*",
      "codecommit:GitPull",
      "codedeploy:Get*",
      "codedeploy:List*",
      "codedeploy:BatchGet*",
      "codepipeline:List*",
      "codepipeline:Get*",
      "config:Describe*",
      "config:List*",
      "config:BatchGet*",
      "config:Deliver*",
      "config:Get*",
      "cur:Describe*",
      "ce:Get*",
      "dynamodb:List*",
      "dynamodb:BatchGet*",
      "dynamodb:ConditionCheckItem",
      "dynamodb:Describe*",
      "dynamodb:Get*",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dax:Describe*",
      "dax:BatchGet*",
      "dax:ConditionCheckItem",
      "dax:Get*",
      "dax:List*",
      "dax:Query",
      "dax:Scan",
      "ec2:Describe*",
      "ec2:ExportClientVpn*",
      "ec2:Get*",
      "ec2:SearchTransitGatewayRoutes",
      "ec2messages:Get*",
      "eks:List*",
      "eks:Describe*",
      "ecr:Describe*",
      "ecr:BatchGet*",
      "ecr:Get*",
      "ecr:BatchCheckLayerAvailability",
      "ecr:List*",
      "ecs:List*",
      "ecs:Describe*",
      "elasticache:Describe*",
      "elasticache:List*",
      "elasticloadbalancing:Describe*",
      "glacier:List*",
      "glacier:Describe*",
      "glacier:Get*",
      "glue:Get*",
      "glue:BatchGet*",
      "guardduty:List*",
      "guardduty:Get*",
      "health:Describe*",
      "iam:Get*",
      "iam:List*",
      "iam:Simulate*",
      "inspector:List*",
      "inspector:PreviewAgents",
      "inspector:Get*",
    ]
    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "readonly2" {
  count  = var.iam_readonly_enabled ? 1 : 0
  statement {
    sid    = "ReadOnly2"
    effect = "Allow"
    actions = [
      "kinesis:List*",
      "kinesis:Describe*",
      "kinesis:Get*",
      "kinesis:SubscribeToShard",
      "kinesisanalytics:List*",
      "kinesisanalytics:DescribeApplication",
      "kinesisanalytics:DiscoverInputSchema",
      "kms:List*",
      "kms:DescribeKey",
      "kms:Get*",
      "lambda:List*",
      "lambda:Get*",
      "macie:List*",
      "organizations:List*",
      "organizations:Describe*",
      "pinpoint:Get*",
      "pinpoint:List*",
      "pinpoint:PhoneNumberValidate",
      "ses:List*",
      "ses:Get*",
      "ses:Verify*",
      "sms-voice:GetConfiguration*",
      "sms-voice:List*",
      "quicksight:List*",
      "quicksight:Describe*",
      "quicksight:GetDashboardEmbedUrl",
      "quicksight:GetGroupMapping",
      "rds:Describe*",
      "rds:List*",
      "redshift:Describe*",
      "redshift:ViewQueries*",
      "redshift:List*",
      "redshift:FetchResults",
      "redshift:GetReservedNodeExchangeOfferings",
      "ram:List*",
      "tag:Get*",
      "resource-groups:List*",
      "resource-groups:SearchResources",
      "resource-groups:Get*",
      "route53:Get*",
      "route53:List*",
      "route53:TestDNSAnswer",
      "route53resolver:List*",
      "route53resolver:Get*",
      "route53domains:List*",
      "route53domains:CheckDomainAvailability",
      "route53domains:ViewBilling",
      "route53domains:Get*",
      "s3:HeadBucket",
      "s3:List*",
      "s3:Get*",
      "secretsmanager:ListSecrets",
      "secretsmanager:DescribeSecret",
      "secretsmanager:Get*",
      "secretsmanager:ListSecretVersionIds",
      "securityhub:Get*",
      "securityhub:List*",
      "serverlessrepo:List*",
      "serverlessrepo:Get*",
      "serverlessrepo:SearchApplications",
      "shield:List*",
      "shield:Describe*",
      "shield:GetSubscriptionState",
      "sns:List*",
      "sns:CheckIfPhoneNumberIsOptedOut",
      "sns:Get*",
      "sqs:List*",
      "sqs:Get*",
      "states:List*",
      "states:Describe*",
      "states:Get*",
      "sts:Get*",
      "support:Describe*",
      "ssm:Describe*",
      "ssm:List*",
      "ssm:Get*",
      "ssm:PutConfigurePackageResult",
      "trustedadvisor:Describe*",
      "waf:List*",
      "waf:Get*",
      "waf-regional:List*",
      "waf-regional:Get*",
      "xray:BatchGetTraces",
      "xray:Get*",
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role" "readonly" {
  count  = var.iam_readonly_enabled ? 1 : 0

  name                 = "ReadOnly"
  assume_role_policy   = data.aws_iam_policy_document.master_account_assumerole.json
  path                 = "/"
  max_session_duration = 43200 #seconds
}

resource "aws_iam_policy" "readonly1" {
  count = var.iam_readonly_enabled ? 1 : 0

  name        = "ReadOnly1"
  path        = "/"
  description = "Read only permissions"
  policy      = data.aws_iam_policy_document.readonly1[0].json
}

resource "aws_iam_policy" "readonly2" {
  count = var.iam_readonly_enabled ? 1 : 0

  name        = "ReadOnly2"
  path        = "/"
  description = "Read only permissions"
  policy      = data.aws_iam_policy_document.readonly2[0].json
}

resource "aws_iam_role_policy_attachment" "readonly1" {
  count = var.iam_readonly_enabled ? 1 : 0

  role       = aws_iam_role.readonly[0].name
  policy_arn = aws_iam_policy.readonly1[0].arn
}

resource "aws_iam_role_policy_attachment" "readonly2" {
  count = var.iam_readonly_enabled ? 1 : 0

  role       = aws_iam_role.readonly[0].name
  policy_arn = aws_iam_policy.readonly2[0].arn
}

resource "aws_iam_role_policy_attachment" "readonly_rds_delete_prevent" {
  count = var.iam_readonly_enabled ? 1 : 0

  role       = aws_iam_role.readonly[0].name
  policy_arn = aws_iam_policy.rds_delete_prevent.arn
}

resource "aws_iam_role_policy_attachment" "readonly_region_restriction" {
  count = var.iam_readonly_enabled ? 1 : 0

  role       = aws_iam_role.readonly[0].name
  policy_arn = aws_iam_policy.region_restriction.arn
}
