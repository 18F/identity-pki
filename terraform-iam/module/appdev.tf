module "appdev-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=master"

  role_name                = "AppDev"
  enabled                  = var.iam_appdev_enabled
  master_assumerole_policy = local.master_assumerole_policy
  custom_policy_arns       = local.custom_policy_arns

  iam_policies = [
    {
      policy_name        = "AppDev"
      policy_description = "Policy for AppDev user with MFA"
      policy_document = [
        {
          sid    = "Autoscaling"
          effect = "Allow"
          actions = [
            "autoscaling:*",
          ]
          resources = [
            "*",
          ]
        },
        {
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
        },
        {
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
        },
        {
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
        },
        {
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
        },
        {
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
        },
        {
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
        },
        {
          sid    = "RDS"
          effect = "Allow"
          actions = [
            "rds:Describe*",
            "rds:List*",
          ]
          resources = [
            "*",
          ]
        },
        {
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
        },
        {
          sid    = "STS"
          effect = "Allow"
          actions = [
            "sts:DecodeAuthorizationMessage",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "Lambda"
          effect = "Allow"
          actions = [
            "lambda:*",
          ]
          resources = [
            "*",
          ]
        },
        {
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
        },
        {
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
        },
        {
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
        },
        {
          sid    = "ElasticCache"
          effect = "Allow"
          actions = [
            "elasticache:Describe*",
            "elasticache:List*",
          ]
          resources = [
            "*",
          ]
        },
        {
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
        },
        {
          sid    = "S3"
          effect = "Allow"
          actions = [
            "s3:List*",
            "s3:Get*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "S3LogosWrite"
          effect = "${var.dashboard_logos_bucket_write == true ? "Allow" : "Deny"}"
          actions = [
            "s3:PutObject",
            "s3:AbortMultipartUpload",
            "s3:ListBucket",
            "s3:GetObject",
            "s3:DeleteObject",
          ]
          resources = [
            "arn:aws:s3:::login-gov-partner-logos-*",
            "arn:aws:s3:::login-gov-partner-logos-*/*",
          ]
        },
        {
          sid    = "SES"
          effect = "Allow"
          actions = [
            "ses:List*",
            "ses:Get*",
          ]
          resources = [
            "*",
          ]
        },
      ]
    },
  ]
}
