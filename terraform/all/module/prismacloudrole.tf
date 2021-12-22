resource "aws_iam_role" "PrismaCloud-connect-role" {
  name               = "PrismaCloudRole"
  assume_role_policy = data.aws_iam_policy_document.PrismaCloud-trust.json
}
resource "aws_iam_policy" "PrismaCloud-connect-policy" {
  name        = "PrismaCloud-connect"
  description = "PrismaCloud Connection Policy"
  policy      = data.aws_iam_policy_document.prismacloud-policy.json
}

resource "aws_iam_policy_attachment" "PrismaCloud-connect-policy-attach" {
  name       = "PrismaCloud-ro-policy-attach"
  roles      = [aws_iam_role.PrismaCloud-connect-role.name]
  policy_arn = aws_iam_policy.PrismaCloud-connect-policy.arn
}

resource "aws_iam_role_policy_attachment" "PrismaCloud-connect-policy-attach-2" {
  role       = aws_iam_role.PrismaCloud-connect-role.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

data "aws_iam_policy_document" "PrismaCloud-trust" {
  statement {
    sid     = "trust"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.accountNumberPrisma}:root",
        "arn:aws-us-gov:iam::${var.govAccountNumberPrisma}:root",
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.externalId]
    }

  }
}

data "aws_iam_policy_document" "prismacloud-policy" {
  statement {
    sid    = "ebs_read_only"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = ["arn:aws:s3:::elasticbeanstalk-*/*"] ## we don't have the aws-us-gov in login-* accounts ? confirm
  }
  statement {
    sid    = "prismacloudpolicy"
    effect = "Allow"
    actions = [
      "apigateway:GET",
      "backup:ListBackupVaults",
      "backup:ListTags",
      "backup:GetBackupVaultAccessPolicy",
      "cloudwatch:ListTagsForResource",
      "cognito-identity:ListTagsForResource",
      "cognito-idp:ListTagsForResource",
      "ds:ListTagsForResource",
      "dynamodb:ListTagsOfResource",
      "ec2:SearchTransitGatewayRoutes",
      "ec2:GetEbsEncryptionByDefault",
      "ecr:DescribeImages",
      "ecr:GetLifecyclePolicy",
      "ecr:ListTagsForResource",
      "eks:ListFargateProfiles",
      "eks:DescribeFargateProfile",
      "eks:ListTagsForResource",
      "elasticbeanstalk:ListTagsForResource",
      "elasticfilesystem:DescribeFileSystemPolicy",
      "elasticfilesystem:DescribeTags",
      "elasticache:ListTagsForResource",
      "es:ListTags",
      "glacier:GetVaultLock",
      "glacier:ListTagsForVault",
      "glue:GetConnections",
      "glue:GetSecurityConfigurations",
      "kafka:ListClusters",
      "logs:GetLogEvents",
      "mq:listBrokers",
      "mq:describeBroker",
      "ram:GetResourceShares",
      "sns:ListTagsForResource",
      "sns:ListPlatformApplications",
      "ssm:GetDocument",
      "ssm:GetParameters",
      "ssm:ListTagsForResource",
      "sqs:SendMessage",
      "elasticmapreduce:ListSecurityConfigurations",
      "elasticmapreduce:GetBlockPublicAccessConfiguration",
      "sns:listSubscriptions",
      "wafv2:ListResourcesForWebACL",
      "wafv2:ListWebACLs",
      "wafv2:ListTagsForResource",
      "wafv2:GetWebACL",
      "wafv2:GetLoggingConfiguration",
      "waf:GetWebACL",
      "waf:ListTagsForResource",
      "waf-regional:GetLoggingConfiguration",
      "waf:GetLoggingConfiguration",
      "waf-regional:ListResourcesForWebACL",
      "waf-regional:ListTagsForResource",
      "codebuild:BatchGetProjects",
      "s3:DescribeJob",
      "s3:ListJobs",
      "s3:GetJobTagging",
      "ssm:GetInventory",
      "shield:GetSubscriptionState",
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetLifecyclePolicyPreview",
      "kms:Decrypt",
      "secretsmanager:GetSecretValue",
      "lambda:GetLayerVersion",
      "ssm:GetParameter",
      "securityhub:BatchImportFindings",
      "lambda:GetFunction"
    ]
    resources = ["*"]
  }
}

