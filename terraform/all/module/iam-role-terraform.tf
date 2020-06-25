module "terraform-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=master"

  role_name                = "Terraform"
  enabled                  = lookup(
                                merge(local.role_enabled_defaults,var.account_roles_map),
                                "iam_terraform_enabled",
                                lookup(local.role_enabled_defaults,"iam_terraform_enabled")
                              )
  master_assumerole_policy = local.master_assumerole_policy
  custom_policy_arns       = local.custom_policy_arns

  iam_policies = [
    {
      policy_name        = "Terraform1"
      policy_description = "Policy 1 for Terraform role"
      policy_document    = [
        {
          sid       = "Acm"
          effect    = "Allow"
          actions   = [
            "acm:DeleteCertificate",
            "acm:DescribeCertificate",
            "acm:ListTagsForCertificate",
            "acm:RequestCertificate",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid       = "Autoscaling"
          effect    = "Allow"
          actions   = [
            "autoscaling:CreateAutoScalingGroup",
            "autoscaling:DeleteAutoScalingGroup",
            "autoscaling:DeleteLifecycleHook",
            "autoscaling:DeletePolicy",
            "autoscaling:DeleteScheduledAction",
            "autoscaling:DescribeAutoScalingGroups",
            "autoscaling:DescribeLifecycleHooks",
            "autoscaling:DescribePolicies",
            "autoscaling:DescribeScheduledActions",
            "autoscaling:EnableMetricsCollection",
            "autoscaling:PutLifecycleHook",
            "autoscaling:PutScalingPolicy",
            "autoscaling:PutScheduledUpdateGroupAction",
            "autoscaling:SetInstanceProtection",
            "autoscaling:UpdateAutoScalingGroup",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid       = "Cloudfront"
          effect    = "Allow"
          actions   = [
            "cloudfront:CreateCloudFrontOriginAccessIdentity",
            "cloudfront:DeleteCloudFrontOriginAccessIdentity",
            "cloudfront:GetCloudFrontOriginAccessIdentity",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid       = "Cloudwatch"
          effect    = "Allow"
          actions   = [
            "cloudwatch:DeleteAlarms",
            "cloudwatch:DeleteDashboards",
            "cloudwatch:DescribeAlarms",
            "cloudwatch:GetDashboard",
            "cloudwatch:ListTagsForResource",
            "cloudwatch:PutDashboard",
            "cloudwatch:PutMetricAlarm",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid       = "Dynamodb"
          effect    = "Allow"
          actions   = [
            "dynamodb:CreateTable",
            "dynamodb:DeleteItem",
            "dynamodb:DeleteTable",
            "dynamodb:DescribeContinuousBackups",
            "dynamodb:DescribeTable",
            "dynamodb:DescribeTimeToLive",
            "dynamodb:GetItem",
            "dynamodb:ListTagsOfResource",
            "dynamodb:PutItem",
            "dynamodb:TagResource",
            "dynamodb:UpdateContinuousBackups",
            "dynamodb:UpdateTimeToLive",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid       = "Ec2"
          effect    = "Allow"
          actions   = [
            "ec2:AttachInternetGateway",
            "ec2:AuthorizeSecurityGroupEgress",
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:CreateFlowLogs",
            "ec2:CreateInternetGateway",
            "ec2:CreateLaunchTemplate",
            "ec2:CreateNetworkAcl",
            "ec2:CreateNetworkAclEntry",
            "ec2:CreateRoute",
            "ec2:CreateSecurityGroup",
            "ec2:CreateSubnet",
            "ec2:CreateTags",
            "ec2:CreateVpc",
            "ec2:CreateVpcEndpoint",
            "ec2:DeleteFlowLogs",
            "ec2:DeleteInternetGateway",
            "ec2:DeleteLaunchTemplate",
            "ec2:DeleteNetworkAcl",
            "ec2:DeleteNetworkAclEntry",
            "ec2:DeleteRoute",
            "ec2:DeleteSecurityGroup",
            "ec2:DeleteSubnet",
            "ec2:DeleteVpc",
            "ec2:DeleteVpcEndpoints",
            "ec2:DescribeAccountAttributes",
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeFlowLogs",
            "ec2:DescribeInstances",
            "ec2:DescribeInternetGateways",
            "ec2:DescribeLaunchTemplates",
            "ec2:DescribeLaunchTemplateVersions",
            "ec2:DescribeNetworkAcls",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DescribePrefixLists",
            "ec2:DescribeRouteTables",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeSubnets",
            "ec2:DescribeVpcAttribute",
            "ec2:DescribeVpcClassicLink",
            "ec2:DescribeVpcClassicLinkDnsSupport",
            "ec2:DescribeVpcEndpoints",
            "ec2:DescribeVpcs",
            "ec2:DetachInternetGateway",
            "ec2:DetachNetworkInterface",
            "ec2:ModifySubnetAttribute",
            "ec2:ModifyVpcAttribute",
            "ec2:ReplaceNetworkAclAssociation",
            "ec2:RevokeSecurityGroupEgress",
            "ec2:RunInstances",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid       = "Elasticache"
          effect    = "Allow"
          actions   = [
            "elasticache:CreateCacheSubnetGroup",
            "elasticache:CreateReplicationGroup",
            "elasticache:DeleteReplicationGroup",
            "elasticache:DeleteCacheSubnetGroup",
            "elasticache:DescribeCacheClusters",
            "elasticache:DescribeCacheSubnetGroups",
            "elasticache:DescribeReplicationGroups",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid       = "Elasticloadbalancing"
          effect    = "Allow"
          actions   = [
            "elasticloadbalancing:AddTags",
            "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
            "elasticloadbalancing:AttachLoadBalancerToSubnets",
            "elasticloadbalancing:ConfigureHealthCheck",
            "elasticloadbalancing:CreateListener",
            "elasticloadbalancing:CreateLoadBalancer",
            "elasticloadbalancing:CreateLoadBalancerListeners",
            "elasticloadbalancing:CreateTargetGroup",
            "elasticloadbalancing:DeleteListener",
            "elasticloadbalancing:DeleteLoadBalancer",
            "elasticloadbalancing:DeleteTargetGroup",
            "elasticloadbalancing:DescribeListeners",
            "elasticloadbalancing:DescribeLoadBalancerAttributes",
            "elasticloadbalancing:DescribeLoadBalancers",
            "elasticloadbalancing:DescribeTags",
            "elasticloadbalancing:DescribeTargetGroupAttributes",
            "elasticloadbalancing:DescribeTargetGroups",
            "elasticloadbalancing:ModifyLoadBalancerAttributes",
            "elasticloadbalancing:ModifyTargetGroup",
            "elasticloadbalancing:ModifyTargetGroupAttributes",
            "elasticloadbalancing:SetSecurityGroups",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid       = "Events"
          effect    = "Allow"
          actions   = [
            "events:DeleteRule",
            "events:DescribeRule",
            "events:EnableRule",
            "events:ListTagsForResource",
            "events:ListTargetsByRule",
            "events:PutRule",
            "events:PutTargets",
            "events:RemoveTargets",
          ]
          resources = [
            "*",
          ]
        }
      ]
    },
    {
      policy_name        = "Terraform2"
      policy_description = "Policy 2 for Terraform role"
      policy_document = [
        {
          sid       = "Iam"
          effect    = "Allow"
          actions   = [
            "iam:AddRoleToInstanceProfile",
            "iam:AttachRolePolicy",
            "iam:CreateInstanceProfile",
            "iam:CreatePolicy",
            "iam:CreateRole",
            "iam:DeleteInstanceProfile",
            "iam:DeleteRole",
            "iam:DeleteRolePolicy",
            "iam:GetInstanceProfile",
            "iam:GetPolicy",
            "iam:GetPolicyVersion",
            "iam:GetRole",
            "iam:GetRolePolicy",
            "iam:ListAccountAliases",
            "iam:ListAttachedRolePolicies",
            "iam:ListInstanceProfilesForRole",
            "iam:PassRole",
            "iam:PutRolePolicy",
            "iam:RemoveRoleFromInstanceProfile",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid       = "Kinesis"
          effect    = "Allow"
          actions   = [
            "kinesis:AddTagsToStream",
            "kinesis:CreateStream",
            "kinesis:DeleteStream",
            "kinesis:DescribeStream",
            "kinesis:EnableEnhancedMonitoring",
            "kinesis:IncreaseStreamRetentionPeriod",
            "kinesis:ListTagsForStream",
            "kinesis:StartStreamEncryption",
            "kinesis:UpdateShardCount",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid       = "Kms"
          effect    = "Allow"
          actions   = [
            "kms:CreateAlias",
            "kms:CreateGrant",
            "kms:CreateKey",
            "kms:Decrypt",
            "kms:DeleteAlias",
            "kms:DescribeKey",
            "kms:EnableKeyRotation",
            "kms:Encrypt",
            "kms:GenerateDataKey",
            "kms:GetKeyPolicy",
            "kms:GetKeyRotationStatus",
            "kms:ListAliases",
            "kms:ListResourceTags",
            "kms:PutKeyPolicy",
            "kms:ScheduleKeyDeletion",
            "kms:TagResource",
            "kms:UpdateKeyDescription",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid       = "Lambda"
          effect    = "Allow"
          actions   = [
            "lambda:CreateEventSourceMapping*",
            "lambda:CreateFunction*",
            "lambda:DeleteEventSourceMapping*",
            "lambda:DeleteFunction*",
            "lambda:GetEventSourceMapping*",
            "lambda:GetFunction*",
            "lambda:ListVersionsByFunction*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid       = "Logs"
          effect    = "Allow"
          actions   = [
            "logs:CreateLogDelivery",
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:DeleteDestination",
            "logs:DeleteLogDelivery",
            "logs:DeleteLogGroup",
            "logs:DeleteMetricFilter",
            "logs:DeleteSubscriptionFilter",
            "logs:DescribeDestinations",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:DescribeMetricFilters",
            "logs:DescribeSubscriptionFilters",
            "logs:ListTagsLogGroup",
            "logs:PutDestination",
            "logs:PutDestinationPolicy",
            "logs:PutLogEvents",
            "logs:PutMetricFilter",
            "logs:PutSubscriptionFilter",
            "logs:TagLogGroup",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid       = "Rds"
          effect    = "Allow"
          actions   = [
            "rds:AddTagsToResource",
            "rds:CreateDBInstance",
            "rds:CreateDBParameterGroup",
            "rds:CreateDBSubnetGroup",
            "rds:DeleteDBInstance",
            "rds:DescribeDBInstances",
            "rds:DescribeDBParameterGroups",
            "rds:DescribeDBParameters",
            "rds:DescribeDBSubnetGroups",
            "rds:ListTagsForResource",
            "rds:ModifyDBInstance",
            "rds:ModifyDBParameterGroup",
            "rds:DeleteDBParameterGroup",
            "rds:DeleteDBSubnetGroup",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid       = "Route53"
          effect    = "Allow"
          actions   = [
            "route53:ChangeResourceRecordSets",
            "route53:CreateHostedZone",
            "route53:DeleteHostedZone",
            "route53:GetChange",
            "route53:GetHostedZone",
            "route53:ListResourceRecordSets",
            "route53:ListTagsForResource",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid       = "S3"
          effect    = "Allow"
          actions   = [
            "s3:CreateBucket",
            "s3:DeleteBucket",
            "s3:DeleteBucketPolicy",
            "s3:DeleteObject",
            "s3:DeleteObjectVersion",
            "s3:GetAccelerateConfiguration",
            "s3:GetBucketCors",
            "s3:GetBucketEncryption",
            "s3:GetBucketLifecycle",
            "s3:GetBucketLocation",
            "s3:GetBucketLogging",
            "s3:GetBucketObjectLockConfiguration",
            "s3:GetBucketPolicy",
            "s3:GetBucketReplication",
            "s3:GetBucketRequestPayment",
            "s3:GetBucketTagging",
            "s3:GetBucketVersioning",
            "s3:GetBucketWebsite",
            "s3:GetEncryptionConfiguration",
            "s3:GetLifecycleConfiguration",
            "s3:GetObject",
            "s3:GetObjectAcl",
            "s3:GetObjectTagging",
            "s3:GetObjectVersionForReplication",
            "s3:GetReplicationConfiguration",
            "s3:ListBucket",
            "s3:ListBucketVersions",
            "s3:ListAllMyBuckets",
            "s3:ListObjectsV2",
            "s3:ListObjectVersions",
            "s3:PutAccelerateConfiguration",
            "s3:PutBucketAcl",
            "s3:PutBucketEncryption",
            "s3:PutBucketLifecycle",
            "s3:PutBucketLogging",
            "s3:PutBucketPolicy",
            "s3:PutBucketTagging",
            "s3:PutBucketVersioning",
            "s3:PutBucketWebsite",
            "s3:PutEncryptionConfiguration",
            "s3:PutLifecycleConfiguration",
            "s3:PutObject",
            "s3:PutReplicationConfiguration",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid       = "Sns"
          effect    = "Allow"
          actions   = [
            "sns:CreateTopic",
            "sns:DeleteTopic",
            "sns:GetSubscriptionAttributes",
            "sns:GetTopicAttributes",
            "sns:ListTagsForResource",
            "sns:SetTopicAttributes",
            "sns:Subscribe",
            "sns:Unsubscribe",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid       = "Sqs"
          effect    = "Allow"
          actions   = [
            "sqs:CreateQueue",
            "sqs:DeleteQueue",
            "sqs:GetQueueAttributes",
            "sqs:GetQueueUrl",
            "sqs:ListDeadLetterSourceQueues",
            "sqs:ListQueues",
            "sqs:ListQueueTags",
            "sqs:PurgeQueue",
            "sqs:SetQueueAttributes",
            "sqs:SetQueueAttributes",
            "sqs:TagQueue",
            "sqs:UntagQueue",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid       = "Sts"
          effect    = "Allow"
          actions   = [
            "sts:GetCallerIdentity",
          ]
          resources = [
            "*",
          ]
        }
      ]
    }
  ]
}
