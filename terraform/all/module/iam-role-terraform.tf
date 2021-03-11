module "autotf-terraform-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=main"

  role_name = "AutoTerraform"
  enabled = lookup(
    merge(local.role_enabled_defaults, var.account_roles_map),
    "iam_auto_terraform_enabled",
    lookup(local.role_enabled_defaults, "iam_auto_terraform_enabled")
  )
  master_assumerole_policy = data.aws_iam_policy_document.autotf_assumerole.json
  custom_policy_arns       = local.custom_policy_arns

  iam_policies = [
    {
      policy_name        = "AutoTerraform1"
      policy_description = "Policy 1 for AutoTerraform role"
      policy_document    = local.Terraform1
    },
    {
      policy_name        = "AutoTerraform2"
      policy_description = "Policy 2 for AutoTerraform role"
      policy_document    = local.Terraform2
    }
  ]
}


module "terraform-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=main"

  role_name = "Terraform"
  enabled = lookup(
    merge(local.role_enabled_defaults, var.account_roles_map),
    "iam_terraform_enabled",
    lookup(local.role_enabled_defaults, "iam_terraform_enabled")
  )
  master_assumerole_policy = local.master_assumerole_policy
  custom_policy_arns       = local.custom_policy_arns

  iam_policies = [
    {
      policy_name        = "Terraform1"
      policy_description = "Policy 1 for Terraform role"
      policy_document    = local.Terraform1
    },
    {
      policy_name        = "Terraform2"
      policy_description = "Policy 2 for Terraform role"
      policy_document    = local.Terraform2
    }
  ]
}

locals {
  Terraform1 = [
    {
      sid    = "AccessAnalyzer"
      effect = "Allow"
      actions = [
        "access-analyzer:*",
      ]
      resources = [
        "*",
      ]
    },
    {
      sid    = "Acm"
      effect = "Allow"
      actions = [
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
      sid    = "Autoscaling"
      effect = "Allow"
      actions = [
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
      sid    = "CloudFormation"
      effect = "Allow"
      actions = [
        "cloudformation:DeleteStack",
        "cloudformation:DescribeStacks",
        "cloudformation:GetTemplate",
      ]
      resources = [
        "*",
      ]
    },
    {
      sid    = "Cloudfront"
      effect = "Allow"
      actions = [
        "cloudfront:*",
      ]
      resources = [
        "*",
      ]
    },
    {
      sid    = "CloudTrail"
      effect = "Allow"
      actions = [
        "cloudtrail:*",
      ]
      resources = [
        "*",
      ]
    },
    {
      sid    = "Cloudwatch"
      effect = "Allow"
      actions = [
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
      sid    = "CodeTools"
      effect = "Allow"
      actions = [
        "codebuild:*",
        "codepipeline:*",
        "codecommit:*",
        "codedeploy:*",
        "codestar-notifications:*"
      ]
      resources = [
        "*",
      ]
    },
    {
      sid    = "Config"
      effect = "Allow"
      actions = [
        "config:*",
      ]
      resources = [
        "*",
      ]
    },
    {
      sid    = "Dynamodb"
      effect = "Allow"
      actions = [
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
      sid    = "Ec2"
      effect = "Allow"
      actions = [
        "ec2:AttachInternetGateway",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CreateFlowLogs",
        "ec2:CreateInternetGateway",
        "ec2:CreateLaunchTemplate",
        "ec2:CreateLaunchTemplateVersion",
        "ec2:CreateNatGateway",
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
        "ec2:DeleteLaunchTemplateVersion",
        "ec2:DeleteNatGateway",
        "ec2:DeleteNetworkAcl",
        "ec2:DeleteNetworkAclEntry",
        "ec2:DeleteRoute",
        "ec2:DeleteSecurityGroup",
        "ec2:DeleteSubnet",
        "ec2:DeleteVpc",
        "ec2:DeleteVpcEndpoints",
        "ec2:DescribeAccountAttributes",
        "ec2:DescribeAddresses",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeFlowLogs",
        "ec2:DescribeInstances",
        "ec2:DescribeInternetGateways",
        "ec2:DescribeLaunchTemplates",
        "ec2:DescribeLaunchTemplateVersions",
        "ec2:DescribeNatGateways",
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
        "ec2:DescribeVpcEndpointServices",
        "ec2:DescribeVpcs",
        "ec2:DetachInternetGateway",
        "ec2:DetachNetworkInterface",
        "ec2:DisassociateAddress",
        "ec2:GetTransitGatewayRouteTableAssociations",
        "ec2:ModifySubnetAttribute",
        "ec2:ModifyVpcAttribute",
        "ec2:ReleaseAddress",
        "ec2:ReplaceNetworkAclAssociation",
        "ec2:ReplaceRouteTableAssociation",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:RunInstances",
      ]
      resources = [
        "*",
      ]
    },
    {
      sid    = "Elasticache"
      effect = "Allow"
      actions = [
        "elasticache:CreateCacheSubnetGroup",
        "elasticache:CreateReplicationGroup",
        "elasticache:DeleteReplicationGroup",
        "elasticache:DeleteCacheSubnetGroup",
        "elasticache:DescribeCacheClusters",
        "elasticache:DescribeCacheSubnetGroups",
        "elasticache:DescribeReplicationGroups",
        "elasticache:ListTagsForResource",
        "elasticache:ModifyCacheSubnetGroup",
      ]
      resources = [
        "*",
      ]
    },
    {
      sid    = "Elasticloadbalancing"
      effect = "Allow"
      actions = [
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
        "elasticloadbalancing:AttachLoadBalancerToSubnets",
        "elasticloadbalancing:ConfigureHealthCheck",
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:CreateLoadBalancerListeners",
        "elasticloadbalancing:CreateRule",
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:DeleteRule",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:DescribeLoadBalancerAttributes",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeRules",
        "elasticloadbalancing:DescribeTags",
        "elasticloadbalancing:DescribeTargetGroupAttributes",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:ModifyRule",
        "elasticloadbalancing:ModifyTargetGroup",
        "elasticloadbalancing:ModifyTargetGroupAttributes",
        "elasticloadbalancing:SetRulePriorities",
        "elasticloadbalancing:SetSecurityGroups",
      ]
      resources = [
        "*",
      ]
    },
    {
      sid    = "Events"
      effect = "Allow"
      actions = [
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

  Terraform2 = [
    {
      sid    = "Iam"
      effect = "Allow"
      actions = [
        "iam:AddRoleToInstanceProfile",
        "iam:AddUserToGroup",
        "iam:AttachRolePolicy",
        "iam:AttachUserPolicy",
        "iam:CreateInstanceProfile",
        "iam:CreatePolicy",
        "iam:CreatePolicyVersion",
        "iam:CreateRole",
        "iam:CreateServiceLinkedRole",
        "iam:CreateUser",
        "iam:DeleteAccessKey",
        "iam:DeleteAccountPasswordPolicy",
        "iam:DeleteInstanceProfile",
        "iam:DeleteLoginProfile",
        "iam:DeletePolicy",
        "iam:DeletePolicyVersion",
        "iam:DeleteRole",
        "iam:DeleteRolePolicy",
        "iam:DeleteUser",
        "iam:DetachRolePolicy",
        "iam:DetachUserPolicy",
        "iam:GetAccountPasswordPolicy",
        "iam:GetGroup",
        "iam:GetInstanceProfile",
        "iam:GetPolicy",
        "iam:GetPolicyVersion",
        "iam:GetRole",
        "iam:GetRolePolicy",
        "iam:GetUser",
        "iam:ListAccessKeys",
        "iam:ListAccountAliases",
        "iam:ListAttachedRolePolicies",
        "iam:ListAttachedUserPolicies",
        "iam:ListEntitiesForPolicy",
        "iam:ListGroupsForUser",
        "iam:ListInstanceProfilesForRole",
        "iam:ListMFADevices",
        "iam:ListPolicyVersions",
        "iam:ListSigningCertificates",
        "iam:ListSSHPublicKeys",
        "iam:ListVirtualMFADevices",
        "iam:PassRole",
        "iam:PutRolePolicy",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:RemoveUserFromGroup",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:UpdateAccountPasswordPolicy",
      ]
      resources = [
        "*",
      ]
    },
    {
      sid    = "Kinesis"
      effect = "Allow"
      actions = [
        "kinesis:AddTagsToStream",
        "kinesis:CreateStream",
        "kinesis:DecreaseStreamRetentionPeriod",
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
      sid    = "Kms"
      effect = "Allow"
      actions = [
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
        "kms:UpdateAlias",
        "kms:UpdateKeyDescription",
      ]
      resources = [
        "*",
      ]
    },
    {
      sid    = "Lambda"
      effect = "Allow"
      actions = [
        "lambda:AddPermission",
        "lambda:CreateEventSourceMapping*",
        "lambda:CreateFunction*",
        "lambda:DeleteAlias",
        "lambda:DeleteEventSourceMapping*",
        "lambda:DeleteFunction*",
        "lambda:GetEventSourceMapping*",
        "lambda:GetFunction*",
        "lambda:GetPolicy",
        "lambda:ListVersionsByFunction*",
        "lambda:PublishVersion",
        "lambda:UpdateEventSourceMapping",
        "lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration",
      ]
      resources = [
        "*",
      ]
    },
    {
      sid    = "Logs"
      effect = "Allow"
      actions = [
        "logs:CreateLogDelivery",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DeleteDestination",
        "logs:DeleteLogDelivery",
        "logs:DeleteLogGroup",
        "logs:DeleteMetricFilter",
        "logs:DeleteRetentionPolicy",
        "logs:DeleteSubscriptionFilter",
        "logs:DescribeDestinations",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:DescribeMetricFilters",
        "logs:DescribeQueries",
        "logs:DescribeResourcePolicies",
        "logs:DescribeSubscriptionFilters",
        "logs:GetLogDelivery",
        "logs:ListTagsLogGroup",
        "logs:ListLogDeliveries",
        "logs:PutDestination",
        "logs:PutDestinationPolicy",
        "logs:PutLogEvents",
        "logs:PutMetricFilter",
        "logs:PutResourcePolicy",
        "logs:PutRetentionPolicy",
        "logs:PutSubscriptionFilter",
        "logs:TagLogGroup",
        "logs:UntagLogGroup",
        "logs:UpdateLogDelivery"
      ]
      resources = [
        "*",
      ]
    },
    {
      sid    = "Pinpoint"
      effect = "Allow"
      actions = [
        "mobiletargeting:*",
      ]
      resources = [
        "*",
      ]
    },
    {
      sid    = "Rds"
      effect = "Allow"
      actions = [
        "rds:AddTagsToResource",
        "rds:CreateDBInstance",
        "rds:CreateDBInstanceReadReplica",
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
        "rds:ModifyDBSubnetGroup",
        "rds:RebootDBInstance",
        "rds:DeleteDBParameterGroup",
        "rds:DeleteDBSubnetGroup",
      ]
      resources = [
        "*",
      ]
    },
    {
      sid    = "Route53"
      effect = "Allow"
      actions = [
        "route53:ChangeResourceRecordSets",
        "route53:CreateHostedZone",
        "route53:DeleteHostedZone",
        "route53:GetChange",
        "route53:GetHostedZone",
        "route53:ListResourceRecordSets",
        "route53:ListTagsForResource",
        "route53domains:Get*",
        "route53domains:List*",
        "route53resolver:AssociateResolver*",
        "route53resolver:DisassociateResolver*",
        "route53resolver:Get*",
        "route53resolver:List*",
        "route53resolver:PutResolverRulePolicy",
        "route53resolver:*ResolverQueryLogConfig*",
      ]
      resources = [
        "*",
      ]
    },
    {
      sid    = "S3"
      effect = "Allow"
      actions = [
        "s3:*",
      ]
      resources = [
        "*",
      ]
    },
    {
      sid    = "Sns"
      effect = "Allow"
      actions = [
        "sns:CreateTopic",
        "sns:DeleteTopic",
        "sns:GetSubscriptionAttributes",
        "sns:GetTopicAttributes",
        "sns:ListSubscriptionsByTopic",
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
      sid    = "SecurityHub"
      effect = "Allow"
      actions = [
        "securityhub:GetEnabledStandards",
      ]
      resources = [
        "*",
      ]
    },
    {
      sid    = "SES"
      effect = "Allow"
      actions = [
        "ses:GetIdentityVerificationAttributes",
        "ses:GetIdentityDkimAttributes",
        "ses:DescribeReceiptRule",
      ]
      resources = [
        "*",
      ]
    },
    {
      sid    = "Sqs"
      effect = "Allow"
      actions = [
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
      sid    = "SSM"
      effect = "Allow"
      actions = [
        "ssm:*",
      ]
      resources = [
        "*",
      ]
    },
    {
      sid    = "Sts"
      effect = "Allow"
      actions = [
        "sts:GetCallerIdentity",
      ]
      resources = [
        "*",
      ]
    },
    {
      sid    = "XRay"
      effect = "Allow"
      actions = [
        "xray:*",
      ]
      resources = [
        "*",
      ]
    },
    {
      sid    = "NetworkFirewall"
      effect = "Allow"
      actions = [
        "network-firewall:*",
      ]
      resources = [
        "*",
      ]
    }

  ]
}
