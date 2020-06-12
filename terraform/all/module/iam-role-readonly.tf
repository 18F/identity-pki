module "readonly-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=master"

  role_name                = "ReadOnly"
  enabled                  = lookup(
                                merge(local.role_enabled_defaults,var.account_roles_map),
                                "iam_readonly_enabled",
                                lookup(local.role_enabled_defaults,"iam_readonly_enabled")
                              )
  master_assumerole_policy = local.master_assumerole_policy
  custom_policy_arns       = local.custom_policy_arns

  iam_policies = [
    {
      policy_name        = "ReadOnly1"
      policy_description = "Policy 1 for ReadOnly user"
      policy_document = [
        {
          sid    = "ACM"
          effect = "Allow"
          actions = [
            "acm:Describe*",
            "acm:List*",
            "acm:Get*",
            "acm-pca:List*",
            "acm-pca:Describe*",
            "acm-pca:Get*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "AutoScaling"
          effect = "Allow"
          actions = [
            "application-autoscaling:Describe*",
            "autoscaling:Describe*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "Athena"
          effect = "Allow"
          actions = [
            "athena:List*",
            "athena:Batch*",
            "athena:Get*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "Cloud9"
          effect = "Allow"
          actions = [
            "cloud9:Describe*",
            "cloud9:List*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "CloudFormation"
          effect = "Allow"
          actions = [
            "cloudformation:List*",
            "cloudformation:Describe*",
            "cloudformation:Detect*",
            "cloudformation:Get*",
            "cloudfront:Get*",
            "cloudfront:List*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "CloudHSM"
          effect = "Allow"
          actions = [
            "cloudhsm:List*",
            "cloudhsm:Describe*",
            "cloudhsm:Get*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "CloudTrail"
          effect = "Allow"
          actions = [
            "cloudtrail:Describe*",
            "cloudtrail:Get*",
            "cloudtrail:List*",
            "cloudtrail:LookupEvents",
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
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "Logs"
          effect = "Allow"
          actions = [
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
          sid    = "CodeBuild"
          effect = "Allow"
          actions = [
            "codebuild:List*",
            "codebuild:BatchGet*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "CodeCommit"
          effect = "Allow"
          actions = [
            "codecommit:List*",
            "codecommit:BatchGet*",
            "codecommit:CancelUploadArchive",
            "codecommit:Get*",
            "codecommit:GitPull",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "CodeDeploy"
          effect = "Allow"
          actions = [
            "codedeploy:Get*",
            "codedeploy:List*",
            "codedeploy:BatchGet*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "CodePipeline"
          effect = "Allow"
          actions = [
            "codepipeline:List*",
            "codepipeline:Get*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "Config"
          effect = "Allow"
          actions = [
            "config:Describe*",
            "config:List*",
            "config:BatchGet*",
            "config:Deliver*",
            "config:Get*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "DynamoDB"
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
          sid    = "DAX"
          effect = "Allow"
          actions = [
            "dax:Describe*",
            "dax:BatchGet*",
            "dax:ConditionCheckItem",
            "dax:Get*",
            "dax:List*",
            "dax:Query",
            "dax:Scan",
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
            "ec2:ExportClientVpn*",
            "ec2:Get*",
            "ec2:SearchTransitGatewayRoutes",
            "ec2messages:Get*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "EKS"
          effect = "Allow"
          actions = [
            "eks:List*",
            "eks:Describe*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "ECR"
          effect = "Allow"
          actions = [
            "ecr:Describe*",
            "ecr:BatchGet*",
            "ecr:Get*",
            "ecr:BatchCheckLayerAvailability",
            "ecr:List*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "ECS"
          effect = "Allow"
          actions = [
            "ecs:List*",
            "ecs:Describe*",
            "elasticache:Describe*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "ElastiCache"
          effect = "Allow"
          actions = [
            "elasticache:List*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "LoadBalancing"
          effect = "Allow"
          actions = [
            "elasticloadbalancing:Describe*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "Glacier"
          effect = "Allow"
          actions = [
            "glacier:List*",
            "glacier:Describe*",
            "glacier:Get*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "Glue"
          effect = "Allow"
          actions = [
            "glue:Get*",
            "glue:BatchGet*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "GuardDuty"
          effect = "Allow"
          actions = [
            "guardduty:List*",
            "guardduty:Get*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "Health"
          effect = "Allow"
          actions = [
            "health:Describe*",
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
          sid    = "Inspector"
          effect = "Allow"
          actions = [
            "inspector:List*",
            "inspector:PreviewAgents",
            "inspector:Get*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "Batch"
          effect = "Allow"
          actions = [
            "batch:Describe*",
            "batch:List*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "ROView"
          effect = "Allow"
          actions = [
            "readonly:View*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "Budget"
          effect = "Allow"
          actions = [
            "budget:View*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "CUR"
          effect = "Allow"
          actions = [
            "cur:Describe*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "CE"
          effect = "Allow"
          actions = [
            "ce:Get*",
          ]
          resources = [
            "*",
          ]
        },
      ]
    },
    {
      policy_name        = "ReadOnly2"
      policy_description = "Policy 2 for ReadOnly user"
      policy_document = [
        {
          sid    = "Kinesis"
          effect = "Allow"
          actions = [
            "kinesis:List*",
            "kinesis:Describe*",
            "kinesis:Get*",
            "kinesis:SubscribeToShard",
            "kinesisanalytics:List*",
            "kinesisanalytics:DescribeApplication",
            "kinesisanalytics:DiscoverInputSchema",
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
          sid    = "Lambda"
          effect = "Allow"
          actions = [
            "lambda:List*",
            "lambda:Get*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "Macie"
          effect = "Allow"
          actions = [
            "macie:List*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "Organizations"
          effect = "Allow"
          actions = [
            "organizations:List*",
            "organizations:Describe*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "Pinpoint"
          effect = "Allow"
          actions = [
            "pinpoint:Get*",
            "pinpoint:List*",
            "pinpoint:PhoneNumberValidate",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "SES"
          effect = "Allow"
          actions = [
            "ses:List*",
            "ses:Get*",
            "ses:Verify*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "SMSVoice"
          effect = "Allow"
          actions = [
            "sms-voice:GetConfiguration*",
            "sms-voice:List*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "Quicksight"
          effect = "Allow"
          actions = [
            "quicksight:List*",
            "quicksight:Describe*",
            "quicksight:GetDashboardEmbedUrl",
            "quicksight:GetGroupMapping",
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
          sid    = "RedShift"
          effect = "Allow"
          actions = [
            "redshift:Describe*",
            "redshift:ViewQueries*",
            "redshift:List*",
            "redshift:FetchResults",
            "redshift:GetReservedNodeExchangeOfferings",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "RAM"
          effect = "Allow"
          actions = [
            "ram:List*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "Tags"
          effect = "Allow"
          actions = [
            "tag:Get*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "ResourceGroups"
          effect = "Allow"
          actions = [
            "resource-groups:List*",
            "resource-groups:SearchResources",
            "resource-groups:Get*",
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
          sid    = "S3"
          effect = "Allow"
          actions = [
            "s3:HeadBucket",
            "s3:List*",
            "s3:Get*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "SecretsManager"
          effect = "Allow"
          actions = [
            "secretsmanager:ListSecrets",
            "secretsmanager:DescribeSecret",
            "secretsmanager:Get*",
            "secretsmanager:ListSecretVersionIds",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "SecurityHub"
          effect = "Allow"
          actions = [
            "securityhub:Get*",
            "securityhub:List*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "Serverless"
          effect = "Allow"
          actions = [
            "serverlessrepo:List*",
            "serverlessrepo:Get*",
            "serverlessrepo:SearchApplications",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "Shield"
          effect = "Allow"
          actions = [
            "shield:List*",
            "shield:Describe*",
            "shield:GetSubscriptionState",
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
          sid    = "SQS"
          effect = "Allow"
          actions = [
            "sqs:List*",
            "sqs:Get*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "States"
          effect = "Allow"
          actions = [
            "states:List*",
            "states:Describe*",
            "states:Get*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "STS"
          effect = "Allow"
          actions = [
            "sts:Get*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "Support"
          effect = "Allow"
          actions = [
            "support:Describe*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "SSM"
          effect = "Allow"
          actions = [
            "ssm:Describe*",
            "ssm:List*",
            "ssm:Get*",
            "ssm:PutConfigurePackageResult",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "TrustedAdvisor"
          effect = "Allow"
          actions = [
            "trustedadvisor:Describe*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "WAF"
          effect = "Allow"
          actions = [
            "waf:List*",
            "waf:Get*",
            "waf-regional:List*",
            "waf-regional:Get*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "XRay"
          effect = "Allow"
          actions = [
            "xray:BatchGetTraces",
            "xray:Get*",
          ]
          resources = [
            "*",
          ]
        },
      ]
    },
  ]
}
