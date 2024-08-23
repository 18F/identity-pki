module "terraform-assumerole" {
  for_each = {
    "AutoTerraform" = {
      policy = data.aws_iam_policy_document.autotf_assumerole.json
      enable = "iam_auto_terraform_enabled"
    },
    "Terraform" = {
      policy = data.aws_iam_policy_document.master_account_assumerole.json
      enable = "iam_terraform_enabled"
    }
  }

  source = "github.com/18F/identity-terraform//iam_assumerole?ref=5aa7231e4a3a91a9f4869311fbbaada99a72062b"
  #source = "../../../../identity-terraform/iam_assumerole"

  role_name                       = each.key
  enabled                         = contains(local.enabled_roles, each.value["enable"])
  master_assumerole_policy        = each.value["policy"]
  custom_iam_policies             = var.dnssec_zone_exists ? [data.aws_iam_policy.dnssec_disable_prevent[0].name] : []
  permissions_boundary_policy_arn = aws_iam_policy.permissions_boundary.arn
  iam_policies = [
    for pol in local.terraform_iam_policies : {
      policy_name        = "${each.key}${index(local.terraform_iam_policies, pol) + 1}"
      policy_description = "Policy ${index(local.terraform_iam_policies, pol) + 1} for ${each.key} role"
      policy_document    = pol
    }
  ]
}

locals {
  terraform_iam_policies = [
    [
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
          "acm:AddTagsToCertificate",
          "acm:DeleteCertificate",
          "acm:DescribeCertificate",
          "acm:ListTagsForCertificate",
          "acm:RemoveTagsFromCertificate",
          "acm:RequestCertificate",
        ]
        resources = [
          "*",
        ]
      },
      {
        sid    = "ApiGateway"
        effect = "Allow"
        actions = [
          "apigateway:GET",
          "apigateway:PATCH",
        ]
        resources = [
          "*",
        ]
      },
      {
        sid    = "Athena"
        effect = "Allow"
        actions = [
          "athena:CreateDataCatalog",
          "athena:CreateNamedQuery",
          "athena:CreatePreparedStatement",
          "athena:CreateWorkGroup",
          "athena:DeleteDataCatalog",
          "athena:DeleteNamedQuery",
          "athena:DeletePreparedStatement",
          "athena:DeleteWorkGroup",
          "athena:GetDatabase",
          "athena:GetNamedQuery",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:GetWorkGroup",
          "athena:ListTagsForResource",
          "athena:StartQueryExecution",
          "athena:StopQueryExecution",
          "athena:TagResource",
          "athena:UntagResource",
          "athena:UpdateDataCatalog",
          "athena:UpdateNamedQuery",
          "athena:UpdatePreparedStatement",
          "athena:UpdateWorkGroup",
        ]
        resources = [
          "*",
        ]
      },
      {
        sid    = "Autoscaling"
        effect = "Allow"
        actions = [
          "autoscaling:AttachLoadBalancerTargetGroups",
          "autoscaling:AttachLoadBalancers",
          "autoscaling:CreateAutoScalingGroup",
          "autoscaling:CreateOrUpdateTags",
          "autoscaling:DeleteAutoScalingGroup",
          "autoscaling:DeleteLifecycleHook",
          "autoscaling:DeletePolicy",
          "autoscaling:DeleteScheduledAction",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeInstanceRefreshes",
          "autoscaling:DescribeLifecycleHooks",
          "autoscaling:DescribeLoadBalancers",
          "autoscaling:DescribePolicies",
          "autoscaling:DescribeScheduledActions",
          "autoscaling:DescribeLoadBalancerTargetGroups",
          "autoscaling:DetachLoadBalancers",
          "autoscaling:DetachLoadBalancerTargetGroups",
          "autoscaling:DisableMetricsCollection",
          "autoscaling:EnableMetricsCollection",
          "autoscaling:PutLifecycleHook",
          "autoscaling:PutScalingPolicy",
          "autoscaling:PutScheduledUpdateGroupAction",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:SetInstanceProtection",
          "autoscaling:StartInstanceRefresh",
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
          "cloudformation:CreateStack",
          "cloudformation:DeleteStack",
          "cloudformation:DescribeStack*",
          "cloudformation:GetTemplate",
          "cloudformation:UpdateStack",
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
          "cloudwatch:TagResource",
          "cloudwatch:UntagResource"
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
        sid    = "DLM"
        effect = "Allow"
        actions = [
          "dlm:*",
        ]
        resources = [
          "*",
        ]
      },
      {
        sid    = "DMS"
        effect = "Allow"
        actions = [
          "dms:AddTagsToResource",
          "dms:ApplyPendingMaintenanceAction",
          "dms:CreateEndpoint",
          "dms:CreateReplicationConfig",
          "dms:CreateReplicationInstance",
          "dms:CreateReplicationSubnetGroup",
          "dms:CreateReplicationTask",
          "dms:DeleteCertificate",
          "dms:DeleteConnection",
          "dms:DeleteEndpoint",
          "dms:DeleteReplicationInstance",
          "dms:DeleteReplicationSubnetGroup",
          "dms:DeleteReplicationTask",
          "dms:DescribeAccountAttributes",
          "dms:DescribeCertificates",
          "dms:DescribeEndpoints",
          "dms:DescribeEventSubscriptions",
          "dms:DescribeReplicationInstances",
          "dms:DescribeReplicationSubnetGroups",
          "dms:DescribeReplicationTasks",
          "dms:ImportCertificate",
          "dms:ListTagsForResource",
          "dms:ModifyEndpoint",
          "dms:ModifyReplicationInstance",
          "dms:ModifyReplicationSubnetGroup",
          "dms:ModifyReplicationTask",
          "dms:RemoveTagsFromResource"
        ]
        resources = [
          "*",
        ]
      }
    ],
    [
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
          "dynamodb:UntagResource"
        ]
        resources = [
          "*",
        ]
      },
      {
        sid    = "Ec2"
        effect = "Allow"
        actions = [
          "ec2:AcceptVpcPeeringConnection",
          "ec2:AllocateAddress",
          "ec2:AssociateRouteTable",
          "ec2:AssociateVpcCidrBlock",
          "ec2:AssociateSubnetCidrBlock",
          "ec2:AttachInternetGateway",
          "ec2:AttachVolume",
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
          "ec2:CreateRouteTable",
          "ec2:CreateSecurityGroup",
          "ec2:CreateSubnet",
          "ec2:CreateTags",
          "ec2:CreateVpc",
          "ec2:CreateVolume",
          "ec2:CreateVpcEndpoint",
          "ec2:CreateVpcPeeringConnection",
          "ec2:DeleteFlowLogs",
          "ec2:DeleteInternetGateway",
          "ec2:DeleteLaunchTemplate",
          "ec2:DeleteLaunchTemplateVersion",
          "ec2:DeleteNatGateway",
          "ec2:DeleteNetworkAcl",
          "ec2:DeleteNetworkAclEntry",
          "ec2:DeleteNetworkInterface",
          "ec2:DeleteRoute",
          "ec2:DeleteRouteTable",
          "ec2:DeleteSecurityGroup",
          "ec2:DeleteSubnet",
          "ec2:DeleteTags",
          "ec2:DeleteVpc",
          "ec2:DeleteVolume",
          "ec2:DeleteVpcEndpoints",
          "ec2:DeleteVpcPeeringConnection",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeFlowLogs",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeManagedPrefixLists",
          "ec2:DescribeNatGateways",
          "ec2:DescribeNetworkAcls",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribePrefixLists",
          "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSecurityGroupRules",
          "ec2:DescribeSubnets",
          "ec2:DescribeVolume*",
          "ec2:DescribeVpcAttribute",
          "ec2:DescribeVpcClassicLink",
          "ec2:DescribeVpcClassicLinkDnsSupport",
          "ec2:DescribeVpcEndpoint*",
          "ec2:DescribeVpcPeeringConnections",
          "ec2:DescribeVpcs",
          "ec2:DetachInternetGateway",
          "ec2:DetachNetworkInterface",
          "ec2:DetachVolume",
          "ec2:DisassociateAddress",
          "ec2:DisassociateRouteTable",
          "ec2:DisassociateVpcCidrBlock",
          "ec2:DisassociateSubnetCidrBlock",
          "ec2:GetManagedPrefixListAssociations",
          "ec2:GetManagedPrefixListEntries",
          "ec2:GetTransitGatewayRouteTableAssociations",
          "ec2:ModifySubnetAttribute",
          "ec2:ModifyVpcAttribute",
          "ec2:ModifyVpcEndpoint*",
          "ec2:ModifyVpcPeeringConnectionOptions",
          "ec2:ReleaseAddress",
          "ec2:ReplaceNetworkAclAssociation",
          "ec2:ReplaceRoute",
          "ec2:ReplaceRouteTableAssociation",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RunInstances",
          "ec2:*VpcEndpoint*",
        ]
        resources = [
          "*",
        ]
      },
      {
        sid    = "ECR"
        effect = "Allow"
        actions = [
          "ecr:CreateRepository",
          "ecr:DeleteRepository",
          "ecr:DeleteRepositoryPolicy",
          "ecr:Describe*",
          "ecr:GetLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:GetRegistryPolicy",
          "ecr:GetRegistryScanningConfiguration",
          "ecr:GetRepositoryPolicy",
          "ecr:List*",
          "ecr:PutImageScanningConfiguration",
          "ecr:PutImageTagMutability",
          "ecr:PutLifecyclePolicy",
          "ecr:PutRegistryPolicy",
          "ecr:PutReplicationConfiguration",
          "ecr:SetRepositoryPolicy",
        ]
        resources = [
          "*",
        ]
      },
      {
        sid    = "EKS"
        effect = "Allow"
        actions = [
          "eks:*",
        ]
        resources = [
          "*",
        ]
      },
      {
        sid    = "Elasticache"
        effect = "Allow"
        actions = [
          "elasticache:AddTagsToResource",
          "elasticache:CreateCacheSubnetGroup",
          "elasticache:CreateReplicationGroup",
          "elasticache:DeleteReplicationGroup",
          "elasticache:DeleteCacheSubnetGroup",
          "elasticache:DescribeCacheClusters",
          "elasticache:DescribeCacheSubnetGroups",
          "elasticache:DescribeReplicationGroups",
          "elasticache:ListTagsForResource",
          "elasticache:ModifyCacheParameterGroup",
          "elasticache:ModifyCacheSubnetGroup",
          "elasticache:ModifyReplicationGroup",
          "elasticache:RemoveTagsFromResource",
          "elasticache:CreateCacheParameterGroup",
          "elasticache:DescribeCacheParameterGroups",
          "elasticache:DescribeCacheParameters",
          "elasticache:DeleteCacheParameterGroup"
        ]
        resources = [
          "*",
        ]
      }
    ],
    [
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
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:ModifyRule",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:RemoveTags",
          "elasticloadbalancing:SetRulePriorities",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetWebACL",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DetachLoadBalancerFromSubnets",
        ]
        resources = [
          "*",
        ]
      },
      {
        sid    = "Events"
        effect = "Allow"
        actions = [
          "events:CreateArchive",
          "events:CreateConnection",
          "events:CreateEventBus",
          "events:DeleteEventBus",
          "events:DeleteRule",
          "events:DescribeEventBus",
          "events:DescribeRule",
          "events:EnableRule",
          "events:ListTagsForResource",
          "events:ListTargetsByRule",
          "events:PutRule",
          "events:PutTargets",
          "events:RemoveTargets",
          "events:TagResource",
          "events:UntagResource"
        ]
        resources = [
          "*",
        ]
      },
      {
        sid    = "Firehose"
        effect = "Allow"
        actions = [
          "firehose:CreateDeliveryStream",
          "firehose:DeleteDeliveryStream",
          "firehose:DescribeDeliveryStream",
          "firehose:ListTagsForDeliveryStream",
          "firehose:DeleteDeliveryStream",
          "firehose:List*",
          "firehose:TagDeliveryStream",
          "firehose:UntagDeliveryStream",
          "firehose:UpdateDestination"
        ]
        resources = [
          "*",
        ]
      },
      {
        sid    = "Glue"
        effect = "Allow"
        actions = [
          "glue:BatchCreatePartition",
          "glue:BatchDeletePartition",
          "glue:BatchDeleteTable",
          "glue:CreateCrawler",
          "glue:CreateDatabase",
          "glue:CreatePartition",
          "glue:CreateTable",
          "glue:DeleteCrawler",
          "glue:DeleteDatabase",
          "glue:DeletePartition",
          "glue:DeleteTable",
          "glue:GetCrawler",
          "glue:GetDatabase",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetTags",
          "glue:StartCrawlerSchedule",
          "glue:StopCrawlerSchedule",
          "glue:UpdateCrawler",
          "glue:UpdateCrawlerSchedule",
          "glue:UpdateDatabase",
          "glue:UpdatePartition",
          "glue:UpdateTable",
        ]
        resources = [
          "*",
        ]
      },
      {
        sid    = "GuardDuty"
        effect = "Allow"
        actions = [
          "guardduty:CreateDetector",
          "guardduty:CreatePublishingDestination",
          "guardduty:DeleteDetector",
          "guardduty:DeletePublishingDestination",
          "guardduty:DescribePublishingDestination",
          "guardduty:GetDetector",
          "guardduty:ListDetectors",
          "guardduty:ListPublishingDestinations",
          "guardduty:TagResource",
          "guardduty:UpdateDetector",
          "guardduty:UpdatePublishingDestination",
        ]
        resources = [
          "*",
        ]
      }
    ],
    [
      {
        sid    = "Iam"
        effect = "Allow"
        actions = [
          "iam:AddRoleToInstanceProfile",
          "iam:AddUserToGroup",
          "iam:AttachGroupPolicy",
          "iam:AttachRolePolicy",
          "iam:AttachUserPolicy",
          "iam:CreateAccountAlias",
          "iam:CreateGroup",
          "iam:CreateInstanceProfile",
          "iam:CreatePolicy",
          "iam:CreatePolicyVersion",
          "iam:CreateRole",
          "iam:CreateServiceLinkedRole",
          "iam:CreateUser",
          "iam:DeleteAccountAlias",
          "iam:DeleteAccessKey",
          "iam:DeleteAccountPasswordPolicy",
          "iam:DeleteGroup",
          "iam:DeleteInstanceProfile",
          "iam:DeleteLoginProfile",
          "iam:DeletePolicy",
          "iam:DeletePolicyVersion",
          "iam:DeleteRole",
          "iam:DeleteRolePolicy",
          "iam:DeleteUser",
          "iam:DetachGroupPolicy",
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
          "iam:GetUserPolicy",
          "iam:GetOpenIDConnectProvider",
          "iam:ListAccessKeys",
          "iam:ListAccountAliases",
          "iam:ListAttachedRolePolicies",
          "iam:ListAttachedUserPolicies",
          "iam:ListEntitiesForPolicy",
          "iam:ListGroupsForUser",
          "iam:ListInstanceProfilesForRole",
          "iam:ListMFADevices",
          "iam:ListPolicies",
          "iam:ListPolicyVersions",
          "iam:ListRolePolicies",
          "iam:ListSigningCertificates",
          "iam:ListSSHPublicKeys",
          "iam:ListVirtualMFADevices",
          "iam:PassRole",
          "iam:PutRolePolicy",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:RemoveUserFromGroup",
          "iam:TagInstanceProfile",
          "iam:TagPolicy",
          "iam:TagRole",
          "iam:UntagInstanceProfile",
          "iam:UntagRole",
          "iam:UpdateAccountPasswordPolicy",
          "iam:UpdateAssumeRolePolicy",
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
          "kinesis:DeregisterStreamConsumer",
          "kinesis:DescribeStream",
          "kinesis:DescribeStreamConsumer",
          "kinesis:DescribeStreamSummary",
          "kinesis:DisableEnhancedMonitoring",
          "kinesis:EnableEnhancedMonitoring",
          "kinesis:IncreaseStreamRetentionPeriod",
          "kinesis:ListTagsForStream",
          "kinesis:RegisterStreamConsumer",
          "kinesis:RemoveTagsFromStream",
          "kinesis:StartStreamEncryption",
          "kinesis:UpdateShardCount",
          "kinesis:UpdateStreamMode"
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
          "kms:DisableKey",
          "kms:EnableKey",
          "kms:EnableKeyRotation",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:GetKeyPolicy",
          "kms:GetKeyRotationStatus",
          "kms:GetPublicKey",
          "kms:ListAliases",
          "kms:ListResourceTags",
          "kms:PutKeyPolicy",
          "kms:ReplicateKey",
          "kms:UpdatePrimaryRegion",
          "kms:ScheduleKeyDeletion",
          "kms:Sign",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:UpdateAlias",
          "kms:UpdateKeyDescription"
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
          "lambda:EnableReplication*",
          "lambda:GetEventSourceMapping*",
          "lambda:GetFunction*",
          "lambda:GetPolicy",
          "lambda:ListVersionsByFunction*",
          "lambda:PublishVersion",
          "lambda:PutFunctionConcurrency",
          "lambda:RemovePermission",
          "lambda:TagResource",
          "lambda:UntagResource",
          "lambda:GetLayerVersion",
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
          "logs:AssociateKmsKey",
          "logs:CreateLogDelivery",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DeleteDestination",
          "logs:DeleteLogDelivery",
          "logs:DeleteLogGroup",
          "logs:DeleteLogStream",
          "logs:DeleteMetricFilter",
          "logs:DeleteRetentionPolicy",
          "logs:DeleteSubscriptionFilter",
          "logs:DeleteQueryDefinition",
          "logs:DeleteResourcePolicy",
          "logs:DescribeDestinations",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:DescribeMetricFilters",
          "logs:DescribeQueries",
          "logs:DescribeQueryDefinitions",
          "logs:DescribeResourcePolicies",
          "logs:DescribeSubscriptionFilters",
          "logs:GetLogDelivery",
          "logs:ListTagsLogGroup",
          "logs:ListLogDeliveries",
          "logs:ListTagsForResource",
          "logs:PutDestination",
          "logs:PutDestinationPolicy",
          "logs:PutLogEvents",
          "logs:PutMetricFilter",
          "logs:PutQueryDefinition",
          "logs:PutResourcePolicy",
          "logs:PutRetentionPolicy",
          "logs:PutSubscriptionFilter",
          "logs:TagLogGroup",
          "logs:TagResource",
          "logs:TestMetricFilter",
          "logs:UntagLogGroup",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogStream"
        ]
        resources = [
          "*",
        ]
      }
    ],
    [
      {
        sid    = "Macie"
        effect = "Allow"
        actions = [
          "macie2:*",
        ]
        resources = [
          "*",
        ]
      },
      {
        sid    = "MobileTargetingPinpoint"
        effect = "Allow"
        actions = [
          "mobiletargeting:*",
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
      },
      {
        sid    = "Rds"
        effect = "Allow"
        actions = [
          "rds:AddTagsToResource",
          "rds:CreateDBCluster",
          "rds:CreateDBClusterParameterGroup",
          "rds:CreateDBInstance",
          "rds:CreateDBInstanceReadReplica",
          "rds:CreateDBParameterGroup",
          "rds:CreateDBSubnetGroup",
          "rds:CreateEventSubscription",
          "rds:CreateGlobalCluster",
          "rds:DeleteDBCluster",
          "rds:DeleteDBClusterParameterGroup",
          "rds:DeleteDBInstance",
          "rds:DeleteDBParameterGroup",
          "rds:DeleteDBSubnetGroup",
          "rds:DeleteGlobalCluster",
          "rds:DescribeDBEngineVersions",
          "rds:DeleteEventSubscription",
          "rds:DescribeDBClusterParameterGroups",
          "rds:DescribeDBClusterParameters",
          "rds:DescribeDBClusters",
          "rds:DescribeDBInstances",
          "rds:DescribeDBParameterGroups",
          "rds:DescribeDBParameters",
          "rds:DescribeDBSubnetGroups",
          "rds:DescribeEventSubscriptions",
          "rds:DescribeGlobalClusters",
          "rds:ListTagsForResource",
          "rds:ModifyDBCluster",
          "rds:ModifyDBInstance",
          "rds:ModifyDBClusterParameterGroup",
          "rds:ModifyDBParameterGroup",
          "rds:ModifyDBSubnetGroup",
          "rds:ModifyGlobalCluster",
          "rds:PromoteReadReplicaDBCluster",
          "rds:RebootDBInstance",
          "rds:RemoveFromGlobalCluster",
          "rds:RemoveTagsFromResource",
          "rds:ResetDBClusterParameterGroup",
        ]
        resources = [
          "*",
        ]
      },
      {
        sid    = "Route53"
        effect = "Allow"
        actions = [
          "route53:ActivateKeySigningKey",
          "route53:AssociateVPCWithHostedZone",
          "route53:ChangeResourceRecordSets",
          "route53:ChangeTagsForResource",
          "route53:CreateHostedZone",
          "route53:CreateKeySigningKey",
          "route53:DeactivateKeySigningKey",
          "route53:DeleteHostedZone",
          "route53:DeleteKeySigningKey",
          "route53:DisableHostedZoneDNSSEC",
          "route53:EnableHostedZoneDNSSEC",
          "route53:GetChange",
          "route53:GetDNSSEC",
          "route53:GetHostedZone",
          "route53:ListHostedZones",
          "route53:ListHostedZonesByName",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResource",
          "route53domains:DeleteTagsForDomain",
          "route53domains:Get*",
          "route53domains:List*",
          "route53resolver:AssociateResolver*",
          "route53resolver:DisassociateResolver*",
          "route53resolver:Get*",
          "route53resolver:List*",
          "route53resolver:PutResolverRulePolicy",
          "route53resolver:*ResolverQueryLogConfig*",
          "route53resolver:TagResource",
          "route53resolver:UpdateResolverDnssecConfig",
          "route53resolver:UntagResource"
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
        sid    = "SecretsManager"
        effect = "Allow"
        actions = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:CreateSecret",
          "secretsmanager:RotateSecret",
          "secretsmanager:DescribeSecret",
          "secretsmanager:UpdateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:GetRandomPassword",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:TagResource"
        ]
        resources = [
          "*",
        ]
      },
      {
        sid    = "SecurityHub"
        effect = "Allow"
        actions = [
          "securityhub:DescribeHub",
          "securityhub:DisableSecurityHub",
          "securityhub:EnableSecurityHub",
          "securityhub:GetEnabledStandards",
          "securityhub:UpdateSecurityHubConfiguration",
          "securityhub:BatchEnableStandards",
        ]
        resources = [
          "*",
        ]
      },
      {
        sid    = "SES"
        effect = "Allow"
        actions = [
          "ses:CreateConfigurationSet",
          "ses:CreateConfigurationSetEventDestination",
          "ses:CreateReceiptRule",
          "ses:CreateReceiptRuleSet",
          "ses:CreateReceiptFilter",
          "ses:DeleteConfigurationSet",
          "ses:DeleteConfigurationSetEventDestination",
          "ses:DeleteIdentity",
          "ses:DeleteReceiptRule",
          "ses:DeleteReceiptRuleSet",
          "ses:DescribeActiveReceiptRuleSet",
          "ses:DescribeConfigurationSet",
          "ses:DescribeReceiptRule",
          "ses:DescribeReceiptRuleSet",
          "ses:GetIdentityDkimAttributes",
          "ses:GetIdentityVerificationAttributes",
          "ses:GetIdentityNotificationAttributes",
          "ses:ListReceiptFilters",
          "ses:PutConfigurationSetDeliveryOptions",
          "ses:SetActiveReceiptRuleSet",
          "ses:SetIdentityHeadersInNotificationsEnabled",
          "ses:SetIdentityNotificationTopic",
          "ses:VerifyDomainDkim",
          "ses:VerifyDomainIdentity",
          "ses:UpdateReceiptRule",
        ]
        resources = [
          "*",
        ]
      },
      {
        sid    = "Shield"
        effect = "Allow"
        actions = [
          "shield:ListTagsForResource",
          "shield:DescribeProtection",
          "shield:TagResource",
          "shield:CreateProtection",
          "shield:DeleteProtection",
          "shield:ListProtections",
          "shield:DisableApplicationLayerAutomaticResponse",
          "shield:EnableApplicationLayerAutomaticResponse",
          "shield:UpdateApplicationLayerAutomaticResponse",
        ]
        resources = [
          "*",
        ]
      }
    ],
    [
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
          "sns:ListTopics",
          "sns:SetSubscriptionAttributes",
          "sns:SetTopicAttributes",
          "sns:Subscribe",
          "sns:TagResource",
          "sns:UntagResource",
          "sns:Unsubscribe",
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
        sid    = "WAFV2"
        effect = "Allow"
        actions = [
          "wafv2:AssociateWebACL",
          "wafv2:CreateIPSet",
          "wafv2:CreateRegexPatternSet",
          "wafv2:CreateWebACL",
          "wafv2:DeleteIPSet",
          "wafv2:DeleteLoggingConfiguration",
          "wafv2:DeleteRegexPatternSet",
          "wafv2:DeleteWebACL",
          "wafv2:DisassociateWebACL",
          "wafv2:GetIPSet",
          "wafv2:GetLoggingConfiguration",
          "wafv2:GetRegexPatternSet",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:ListIPSets",
          "wafv2:ListRegexPatternSets",
          "wafv2:ListTagsForResource",
          "wafv2:ListWebACLs",
          "wafv2:PutLoggingConfiguration",
          "wafv2:TagResource",
          "wafv2:UntagResource",
          "wafv2:UpdateIPSet",
          "wafv2:UpdateRegexPatternSet",
          "wafv2:UpdateWebACL",
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
      },
      {
        sid    = "EKS"
        effect = "Allow"
        actions = [
          "eks:*",
        ]
        resources = [
          "*",
        ]
      },
      {
        sid    = "ECR"
        effect = "Allow"
        actions = [
          "ecr:CreateRepository",
          "ecr:DeleteRepository",
          "ecr:DeleteRepositoryPolicy",
          "ecr:Describe*",
          "ecr:GetLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:GetRegistryPolicy",
          "ecr:GetRegistryScanningConfiguration",
          "ecr:GetRepositoryPolicy",
          "ecr:List*",
          "ecr:PutImageScanningConfiguration",
          "ecr:PutImageTagMutability",
          "ecr:PutLifecyclePolicy",
          "ecr:PutRegistryPolicy",
          "ecr:PutReplicationConfiguration",
          "ecr:SetRepositoryPolicy",
        ]
        resources = [
          "*",
        ]
      },
      {
        sid    = "Macie"
        effect = "Allow"
        actions = [
          "macie2:*",
        ]
        resources = [
          "*",
        ]
      },
      {
        sid    = "DLM"
        effect = "Allow"
        actions = [
          "dlm:*",
        ]
        resources = [
          "*",
        ]
      },
      {
        sid    = "Athena"
        effect = "Allow"
        actions = [
          "athena:CreateDataCatalog",
          "athena:CreateNamedQuery",
          "athena:CreatePreparedStatement",
          "athena:CreateWorkGroup",
          "athena:DeleteDataCatalog",
          "athena:DeleteNamedQuery",
          "athena:DeletePreparedStatement",
          "athena:DeleteWorkGroup",
          "athena:GetDatabase",
          "athena:GetNamedQuery",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:GetWorkGroup",
          "athena:ListTagsForResource",
          "athena:StartQueryExecution",
          "athena:StopQueryExecution",
          "athena:TagResource",
          "athena:UntagResource",
          "athena:UpdateDataCatalog",
          "athena:UpdateNamedQuery",
          "athena:UpdatePreparedStatement",
          "athena:UpdateWorkGroup",
        ]
        resources = [
          "*",
        ]
      },
      {
        sid    = "Glue"
        effect = "Allow"
        actions = [
          "glue:BatchCreatePartition",
          "glue:BatchDeletePartition",
          "glue:BatchDeleteTable",
          "glue:CreateCrawler",
          "glue:CreateDatabase",
          "glue:CreatePartition",
          "glue:CreateTable",
          "glue:DeleteCrawler",
          "glue:DeleteDatabase",
          "glue:DeletePartition",
          "glue:DeleteTable",
          "glue:GetCrawler",
          "glue:GetDatabase",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetTags",
          "glue:StartCrawlerSchedule",
          "glue:StopCrawlerSchedule",
          "glue:UpdateCrawler",
          "glue:UpdateCrawlerSchedule",
          "glue:UpdateDatabase",
          "glue:UpdatePartition",
          "glue:UpdateTable",
        ]
        resources = [
          "*",
        ]
      },
      {
        sid    = "GuardDuty"
        effect = "Allow"
        actions = [
          "guardduty:CreateDetector",
          "guardduty:CreatePublishingDestination",
          "guardduty:DeleteDetector",
          "guardduty:DeletePublishingDestination",
          "guardduty:DescribePublishingDestination",
          "guardduty:GetDetector",
          "guardduty:ListDetectors",
          "guardduty:ListPublishingDestinations",
          "guardduty:TagResource",
          "guardduty:UpdateDetector",
          "guardduty:UpdatePublishingDestination",
        ]
        resources = [
          "*",
        ]
      },
      {
        sid    = "DMS"
        effect = "Allow"
        actions = [
          "dms:AddTagsToResource",
          "dms:ApplyPendingMaintenanceAction",
          "dms:CreateEndpoint",
          "dms:CreateReplicationConfig",
          "dms:CreateReplicationInstance",
          "dms:CreateReplicationSubnetGroup",
          "dms:CreateReplicationTask",
          "dms:DeleteCertificate",
          "dms:DeleteConnection",
          "dms:DeleteEndpoint",
          "dms:DeleteReplicationInstance",
          "dms:DeleteReplicationSubnetGroup",
          "dms:DeleteReplicationTask",
          "dms:DescribeAccountAttributes",
          "dms:DescribeCertificates",
          "dms:DescribeEndpoints",
          "dms:DescribeEventSubscriptions",
          "dms:DescribeReplicationInstances",
          "dms:DescribeReplicationSubnetGroups",
          "dms:DescribeReplicationTasks",
          "dms:ImportCertificate",
          "dms:ListTagsForResource",
          "dms:ModifyEndpoint",
          "dms:ModifyReplicationInstance",
          "dms:ModifyReplicationSubnetGroup",
          "dms:ModifyReplicationTask",
          "dms:RemoveTagsFromResource",
          "dms:StopReplicationTask"
        ]
        resources = [
          "*",
        ]
      }
    ],
    [
      {
        sid    = "SSMContacts"
        effect = "Allow"
        actions = [
          "ssm-contacts:ListContactChannels",
          "ssm-contacts:ListContacts",
          "ssm-contacts:ListEngagements",
          "ssm-contacts:ListRotations",
          "ssm-contacts:GetContact",
          "ssm-contacts:GetContactChannel",
          "ssm-contacts:GetContactPolicy",
          "ssm-contacts:GetRotation",
          "ssm-contacts:ListTagsForResource",
          "ssm-contacts:CreateContact",
          "ssm-contacts:CreateContactChannel",
          "ssm-contacts:CreateRotation",
          "ssm-contacts:DeleteContact",
          "ssm-contacts:DeleteContactChannel",
          "ssm-contacts:DeleteRotation",
          "ssm-contacts:PutContactPolicy",
          "ssm-contacts:UpdateContact",
          "ssm-contacts:UpdateContactChannel",
          "ssm-contacts:UpdateRotation",
          "ssm-contacts:AssociateContact",
          "ssm-contacts:TagResource",
          "ssm-contacts:UntagResource"
        ]
        resources = [
          "*",
        ]
      },
      {
        sid    = "Redshift"
        effect = "Allow"
        actions = [
          "redshift:CreateCluster",
          "redshift:CreateClusterParameterGroup",
          "redshift:CreateClusterSubnetGroup",
          "redshift:CreateTags",
          "redshift:DeleteCluster",
          "redshift:DeleteClusterParameterGroup",
          "redshift:DeleteClusterSubnetGroup",
          "redshift:DescribeClusterParameterGroups",
          "redshift:DescribeClusterParameters",
          "redshift:DescribeClusterSubnetGroups",
          "redshift:DescribeClusters",
          "redshift:DescribeLoggingStatus",
          "redshift:EnableLogging",
          "redshift:ModifyClusterParameterGroup",
        ]
        resources = [
          "*",
        ]
      },
      {
        sid    = "SSMIncidents"
        effect = "Allow"
        actions = [
          "ssm-incidents:UntagResource",
          "ssm-incidents:TagResource",
          "ssm-incidents:PutResourcePolicy",
          "ssm-incidents:DeleteResourcePolicy",
          "ssm-incidents:UpdateResponsePlan",
          "ssm-incidents:UpdateReplicationSet",
          "ssm-incidents:UpdateDeletionProtection",
          "ssm-incidents:DeleteResponsePlan",
          "ssm-incidents:DeleteReplicationSet",
          "ssm-incidents:CreateResponsePlan",
          "ssm-incidents:CreateReplicationSet",
          "ssm-incidents:ListTagsForResource",
          "ssm-incidents:GetReplicationSet",
          "ssm-incidents:GetResponsePlan",
          "ssm-incidents:GetResourcePolicies",
          "ssm-incidents:ListResponsePlans",
          "ssm-incidents:ListReplicationSets"
        ]
        resources = [
          "*",
        ]
      },

    ]
  ]
}
