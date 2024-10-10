data "aws_iam_policy" "query_editor_full_access" {
  arn = "arn:aws:iam::aws:policy/AmazonRedshiftQueryEditorV2FullAccess"
}

locals {
  dwadmin_dns_policies = var.dnssec_zone_exists ? [data.aws_iam_policy.dnssec_disable_prevent[0].name] : []
  dwadmin_additional_policies = [
    data.aws_iam_policy.query_editor_full_access.name,
  ]
  dwadmin_custom_iam_policies = flatten([local.dwadmin_dns_policies, local.dwadmin_additional_policies])
}

module "dwadmin-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=5aa7231e4a3a91a9f4869311fbbaada99a72062b"
  #source = "../../../../identity-terraform/iam_assumerole"

  role_name                       = "DWAdmin"
  enabled                         = contains(local.enabled_roles, "iam_dwadmin_enabled")
  master_assumerole_policy        = data.aws_iam_policy_document.master_account_assumerole.json
  custom_iam_policies             = local.dwadmin_custom_iam_policies
  permissions_boundary_policy_arn = aws_iam_policy.permissions_boundary.arn

  iam_policies = [
    {
      policy_name        = "DWAdmin1"
      policy_description = "Policy 1 for DWAdmin role"
      policy_document = [
        {
          sid    = "AccessAnalyzer"
          effect = "Allow"
          actions = [
            "access-analyzer:GetAnalyzer"
          ],
          resources = [
            "*"
          ]
        },
        {
          sid    = "AthenaKMSKeyAccess"
          effect = "Allow"
          actions = [
            "kms:Decrypt",
            "kms:DescribeKey",
            "kms:Encrypt",
            "kms:GenerateDataKey"
          ],
          resources = [
            "*"
          ],
          conditions = [
            {
              test     = "ForAnyValue:StringLike"
              variable = "kms:ResourceAliases"
              values   = ["alias/*-kms-s3-log-cache-bucket"]
            }
          ]
        },
        {
          sid    = "Autoscaling"
          effect = "Allow"
          actions = [
            "autoscaling:CreateOrUpdateTags",
            "autoscaling:DeleteTags",
            "autoscaling:DescribeAutoScalingGroups",
            "autoscaling:DescribeInstanceRefreshes",
            "autoscaling:DescribeLifecycleHooks",
            "autoscaling:DescribeNotificationConfigurations",
            "autoscaling:DescribePolicies",
            "autoscaling:DescribeScalingActivities",
            "autoscaling:DescribeScheduledActions",
            "autoscaling:DescribeTags",
            "autoscaling:DescribeWarmPool",
            "autoscaling:PutScheduledUpdateGroupAction",
            "autoscaling:StartInstanceRefresh",
            "autoscaling:UpdateAutoScalingGroup"
          ],
          resources = [
            "*"
          ]
        },
        {
          sid    = "CloudTrail"
          effect = "Allow"
          actions = [
            "cloudtrail:DescribeTrails",
            "cloudtrail:GetTrailStatus",
            "cloudtrail:ListTags"
          ],
          resources = [
            "*"
          ]
        },
        {
          sid    = "CloudWatch"
          effect = "Allow"
          actions = [
            "cloudwatch:Batch*",
            "cloudwatch:CreateServiceLevelObjective",
            "cloudwatch:DeleteAlarms",
            "cloudwatch:DeleteServiceLevelObjective",
            "cloudwatch:Describe*",
            "cloudwatch:EnableTopologyDiscovery",
            "cloudwatch:GenerateQuery",
            "cloudwatch:GetDashboard",
            "cloudwatch:GetMetricData",
            "cloudwatch:GetMetricWidgetImage",
            "cloudwatch:GetService*",
            "cloudwatch:GetTopology*",
            "cloudwatch:Link",
            "cloudwatch:ListMetric*",
            "cloudwatch:ListServiceLevelObjectives",
            "cloudwatch:ListServices",
            "cloudwatch:ListTagsForResource",
            "cloudwatch:PutMetricAlarm",
            "cloudwatch:PutMetricData",
            "cloudwatch:TagResource",
            "cloudwatch:UntagResource",
            "cloudwatch:UpdateServiceLevelObjective",
            "events:DescribeEventBus",
            "events:DescribeRule",
            "events:InvokeApiDestination",
            "events:ListEventBuses",
            "events:ListRules",
            "events:ListTagsForResource",
            "events:ListTargetsByRule",
            "events:PutEvents",
            "events:PutPartnerEvents",
            "events:RetrieveConnectionCredentials",
            "events:TagResource",
            "events:UntagResource",
            "logs:CreateLogDelivery",
            "logs:CreateLogGroup",
            "logs:DeleteAccountPolicy",
            "logs:DeleteLogDelivery",
            "logs:DeleteLogGroup",
            "logs:DescribeAccountPolicies",
            "logs:DescribeExportTasks",
            "logs:DescribeLog*",
            "logs:DescribeMetricFilters",
            "logs:DescribeQueryDefinitions",
            "logs:DescribeResourcePolicies",
            "logs:DescribeSubscriptionFilters",
            "logs:FilterLogEvents",
            "logs:GetLogDelivery",
            "logs:GetLogEvents",
            "logs:GetLogGroupFields",
            "logs:GetLogRecord",
            "logs:GetQueryResults",
            "logs:Link",
            "logs:List*",
            "logs:PutAccountPolicy",
            "logs:PutLogEvents",
            "logs:PutMetricFilter",
            "logs:PutQueryDefinition",
            "logs:PutRetentionPolicy",
            "logs:Start*",
            "logs:StopLiveTail",
            "logs:Tag*",
            "logs:TestMetricFilter",
            "logs:Unmask",
            "logs:Untag*",
            "logs:UpdateLogDelivery"
          ],
          resources = [
            "*"
          ]
        },
        {
          sid    = "Config"
          effect = "Allow"
          actions = [
            "config:DescribeConfigurationRecorderStatus",
            "config:DescribeConfigurationRecorders",
            "config:DescribeDeliveryChannels"
          ],
          resources = [
            "*"
          ]
        },
        {
          sid    = "DMS"
          effect = "Allow"
          actions = [
            "dms:StopReplication",
            "dms:StopDataMigration",
            "dms:StartReplicationTaskAssessmentRun",
            "dms:StartDataMigration",
            "dms:RemoveTagsFromResource",
            "dms:ListDataProviders",
            "dms:ListExtensionPacks",
            "dms:ListInstanceProfiles",
            "dms:ListMetadataModelAssessments",
            "dms:ListMetadataModelConversions",
            "dms:ListMetadataModelExports",
            "dms:ListMigrationProjects",
            "dms:ListTagsForResource",
            "dms:DescribeConversionConfiguration",
            "dms:DescribeData*",
            "dms:DescribeEndpoints",
            "dms:DescribeEngineVersions",
            "dms:DescribeExtensionPackAssociations",
            "dms:DescribeInstanceProfiles",
            "dms:DescribeMetadataModelAssessments",
            "dms:DescribeMetadataModelConversions",
            "dms:DescribeMetadataModelExports*",
            "dms:DescribeMigrationProjects",
            "dms:DescribeReplicationInstances",
            "dms:DescribeReplicationTaskAssessmentRuns",
            "dms:DescribeReplicationTasks",
            "dms:AssociateExtensionPack",
            "dms:AddTagsToResource"
          ],
          resources = [
            "*"
          ]
        },
      ]
    },
    {
      policy_name        = "DWAdmin2"
      policy_description = "Policy 2 for DWAdmin role"
      policy_document = [

        {
          sid    = "DynamoDb"
          effect = "Allow"
          actions = [
            "dynamodb:Batch*",
            "dynamodb:ConditionCheckItem",
            "dynamodb:CreateTableReplica",
            "dynamodb:DeleteItem",
            "dynamodb:DeleteResourcePolicy",
            "dynamodb:DeleteTableReplica",
            "dynamodb:DescribeContinuousBackups",
            "dynamodb:DescribeReserved*",
            "dynamodb:DescribeTable",
            "dynamodb:DescribeTimeToLive",
            "dynamodb:GetItem",
            "dynamodb:GetRecords",
            "dynamodb:GetShardIterator",
            "dynamodb:ListTagsOfResource",
            "dynamodb:Parti*",
            "dynamodb:PurchaseReservedCapacityOfferings",
            "dynamodb:Put*",
            "dynamodb:Query",
            "dynamodb:RestoreTableFromAwsBackup",
            "dynamodb:Scan",
            "dynamodb:StartAwsBackupJob",
            "dynamodb:TagResource",
            "dynamodb:UntagResource",
            "dynamodb:UpdateGlobalTableVersion",
            "dynamodb:UpdateItem"
          ],
          resources = [
            "*"
          ]
        },
        {
          sid    = "EC2"
          effect = "Allow"
          actions = [
            "ec2:AuthorizeSecurityGroupEgress",
            "ec2:CreateLaunchTemplate",
            "ec2:CreateLaunchTemplateVersion",
            "ec2:CreateSnapshot",
            "ec2:CreateTags",
            "ec2:DeleteLaunchTemplateVersion",
            "ec2:DeleteSnapshot",
            "ec2:DeleteTags",
            "ec2:DescribeAccountAttributes",
            "ec2:DescribeAddresses",
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeCapacityBlockOfferings",
            "ec2:DescribeCapacityReservations",
            "ec2:DescribeCustomerGateways",
            "ec2:DescribeDhcpOptions",
            "ec2:DescribeEgressOnlyInternetGateways",
            "ec2:DescribeFlowLogs",
            "ec2:DescribeHosts",
            "ec2:DescribeImages",
            "ec2:DescribeInstanceAttribute",
            "ec2:DescribeInstanceConnectEndpoints",
            "ec2:DescribeInstanceCreditSpecifications",
            "ec2:DescribeInstanceStatus",
            "ec2:DescribeInstanceTypeOfferings",
            "ec2:DescribeInstanceTypes",
            "ec2:DescribeInstances",
            "ec2:DescribeInternetGateways",
            "ec2:DescribeKeyPairs",
            "ec2:DescribeLaunch*",
            "ec2:DescribeLocalGatewayRouteTablePermissions",
            "ec2:DescribeManagedPrefixLists",
            "ec2:DescribeNatGateways",
            "ec2:DescribeNetworkAcls",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DescribePlacementGroups",
            "ec2:DescribePrefixLists",
            "ec2:DescribeRegions",
            "ec2:DescribeReplaceRootVolumeTasks",
            "ec2:DescribeRouteTables",
            "ec2:DescribeSecurityGroupRules",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeSnapshots",
            "ec2:DescribeSubnets",
            "ec2:DescribeTags",
            "ec2:DescribeVerifiedAccessInstanceWebAclAssociations",
            "ec2:DescribeVolumeStatus",
            "ec2:DescribeVolumes",
            "ec2:DescribeVpcAttribute",
            "ec2:DescribeVpcEndpointServiceConfigurations",
            "ec2:DescribeVpcEndpointServices",
            "ec2:DescribeVpcEndpoints",
            "ec2:DescribeVpcPeeringConnections",
            "ec2:DescribeVpcs",
            "ec2:DescribeVpn*",
            "ec2:StopInstances",
            "ec2:TerminateInstances"
          ],
          resources = [
            "*"
          ]
        },
        {
          sid    = "ELB"
          effect = "Allow"
          actions = [
            "elasticloadbalancing:AddTags",
            "elasticloadbalancing:DescribeAccountLimits",
            "elasticloadbalancing:DescribeListeners",
            "elasticloadbalancing:DescribeLoadBalancerAttributes",
            "elasticloadbalancing:DescribeLoadBalancers",
            "elasticloadbalancing:DescribeTags",
            "elasticloadbalancing:DescribeTargetGroupAttributes",
            "elasticloadbalancing:DescribeTargetGroups",
            "elasticloadbalancing:SetWebACL"
          ],
          resources = [
            "*"
          ]
        },
        {
          sid    = "Firehose"
          effect = "Allow"
          actions = [
            "firehose:List*",
            "firehose:Put*",
            "firehose:TagDeliveryStream",
            "firehose:UntagDeliveryStream"
          ],
          resources = [
            "*"
          ]
        },
        {
          sid    = "GuardDuty"
          effect = "Allow"
          actions = [
            "guardduty:DescribeOrganizationConfiguration",
            "guardduty:DescribePublishingDestination",
            "guardduty:GetDetector",
            "guardduty:GetFindings*",
            "guardduty:GetInvitationsCount",
            "guardduty:GetMasterAccount",
            "guardduty:GetOrganizationStatistics",
            "guardduty:GetRemainingFreeTrialDays",
            "guardduty:GetUsageStatistics",
            "guardduty:ListDetectors",
            "guardduty:ListFilters",
            "guardduty:ListFindings",
            "guardduty:ListMembers",
            "guardduty:ListTagsForResource",
            "guardduty:TagResource",
            "guardduty:UntagResource"
          ],
          resources = [
            "*"
          ]
        },
        {
          sid    = "IAM"
          effect = "Allow"
          actions = [
            "iam:AttachRolePolicy",
            "iam:CreatePolicyVersion",
            "iam:DeletePolicy",
            "iam:DeleteRole",
            "iam:DetachRolePolicy",
            "iam:GenerateServiceLastAccessedDetails",
            "iam:GetAccessKeyLastUsed",
            "iam:GetAccountPasswordPolicy",
            "iam:GetAccountSummary",
            "iam:GetInstanceProfile",
            "iam:GetLoginProfile",
            "iam:GetPolicy*",
            "iam:GetRole*",
            "iam:GetServiceLastAccessedDetails",
            "iam:GetUser",
            "iam:ListAccessKeys",
            "iam:ListAccountAliases",
            "iam:ListAttachedRolePolicies",
            "iam:ListEntitiesForPolicy",
            "iam:ListGroups*",
            "iam:ListInstanceProfileTags",
            "iam:ListInstanceProfilesForRole",
            "iam:ListM*",
            "iam:ListOpen*",
            "iam:ListPolicies",
            "iam:ListPolicy*",
            "iam:ListRolePolicies",
            "iam:ListRoleTags",
            "iam:ListRoles",
            "iam:ListSA*",
            "iam:ListSTSRegionalEndpointsStatus",
            "iam:ListServerCertificateTags",
            "iam:ListSigningCertificates",
            "iam:ListUserTags",
            "iam:ListUsers",
            "iam:PassRole",
            "iam:Tag*",
            "iam:Untag*"
          ],
          resources = [
            "*"
          ]
        },
        {
          sid    = "KMS"
          effect = "Allow"
          actions = [
            "kms:DescribeKey",
            "kms:GetKeyPolicy",
            "kms:GetKeyRotationStatus",
            "kms:ListAliases",
            "kms:ListResourceTags",
            "kms:PutKeyPolicy",
            "kms:TagResource"
          ],
          resources = [
            "*"
          ]
        },
      ]
    },
    {
      policy_name        = "DWAdmin3"
      policy_description = "Policy 3 for DWAdmin role"
      policy_document = [
        {
          sid    = "Lambda"
          effect = "Allow"
          actions = [
            "lambda:DeleteFunction",
            "lambda:DeleteResourcePolicy",
            "lambda:DisableReplication",
            "lambda:EnableReplication",
            "lambda:GetAccountSettings",
            "lambda:GetFunction",
            "lambda:GetFunctionCodeSigningConfig",
            "lambda:GetFunctionEventInvokeConfig",
            "lambda:GetFunctionRecursionConfig",
            "lambda:GetLayerVersion",
            "lambda:GetPolicy",
            "lambda:GetPublicAccessBlockConfig",
            "lambda:GetResourcePolicy",
            "lambda:GetRuntimeManagementConfig",
            "lambda:Invoke*",
            "lambda:ListAliases",
            "lambda:ListEventSourceMappings",
            "lambda:ListFunctionUrlConfigs",
            "lambda:ListFunctions",
            "lambda:ListLayers",
            "lambda:ListProvisionedConcurrencyConfigs",
            "lambda:ListTags",
            "lambda:ListVersionsByFunction",
            "lambda:PutPublicAccessBlockConfig",
            "lambda:PutResourcePolicy",
            "lambda:RemovePermission",
            "lambda:TagResource",
            "lambda:UntagResource",
            "lambda:UpdateFunctionCode*",
            "lambda:UpdateFunctionConfiguration"
          ],
          resources = [
            "*"
          ]
        },
        {
          sid    = "Macie"
          effect = "Allow"
          actions = [
            "macie:*"
          ],
          resources = [
            "*"
          ]
        },
        {
          sid    = "Macie2"
          effect = "Allow"
          actions = [
            "macie2:*"
          ],
          resources = [
            "*"
          ]
        },
        {
          sid    = "Pinpoint"
          effect = "Allow"
          actions = [
            "pinpoint:Get*",
            "pinpoint:List*",
            "pinpoint:PhoneNumberValidate"
          ],
          resources = [
            "*"
          ]
        },
        {
          sid    = "QueryEditorV2KMSKeyAccess"
          effect = "Allow"
          actions = [
            "kms:GenerateDataKey",
            "kms:DescribeKey",
            "kms:Decrypt",
            "kms:ListAliases"
          ],
          resources = [
            "*"
          ],
          conditions = [
            {
              test     = "StringEquals"
              variable = "kms:CallerAccount"
              values   = [data.aws_caller_identity.current.account_id]
            },
            {
              test     = "StringEquals"
              variable = "kms:viaService"
              values   = ["sqlworkbench.us-west-2.amazonaws.com"]
            }
          ]
        },
        {
          sid    = "AmazonRedshiftQueryEditorV2Permissions"
          effect = "Allow"
          actions = [
            "sqlworkbench:*"
          ]
          resources = [
            "*"
          ]
        },
        {
          sid    = "RDS"
          effect = "Allow"
          actions = [
            "rds:AddTagsToResource",
            "rds:CopyCustomDBEngineVersion",
            "rds:CreateBlueGreenDeployment",
            "rds:CreateDBCluster",
            "rds:CreateDBClusterEndpoint",
            "rds:CreateDBClusterSnapshot",
            "rds:CreateDBInstance*",
            "rds:CreateDBShardGroup",
            "rds:CreateDBSnapshot",
            "rds:CreateIntegration",
            "rds:CreateTenantDatabase",
            "rds:CrossRegionCommunication",
            "rds:DeleteCustomDBEngineVersion",
            "rds:DeleteDBCluster",
            "rds:DeleteDBClusterEndpoint",
            "rds:DeleteDBInstance",
            "rds:DeleteDBShardGroup",
            "rds:DeleteIntegration",
            "rds:DeleteTenantDatabase",
            "rds:DescribeAccountAttributes",
            "rds:DescribeBlueGreenDeployments",
            "rds:DescribeCertificates",
            "rds:DescribeDBClusterParameterGroups",
            "rds:DescribeDBClusterParameters",
            "rds:DescribeDBClusterSnapshots",
            "rds:DescribeDBClusters",
            "rds:DescribeDBEngineVersions",
            "rds:DescribeDBInstances",
            "rds:DescribeDBParameterGroups",
            "rds:DescribeDBParameters",
            "rds:DescribeDBRecommendations",
            "rds:DescribeDBSecurityGroups",
            "rds:DescribeDBShardGroups",
            "rds:DescribeDBSnapshots",
            "rds:DescribeDBSubnetGroups",
            "rds:DescribeEventSubscriptions",
            "rds:DescribeEvents",
            "rds:DescribeGlobalClusters",
            "rds:DescribeOptionGroups",
            "rds:DescribeOrderableDBInstanceOptions",
            "rds:DescribePendingMaintenanceActions",
            "rds:DescribeRecommendationGroups",
            "rds:DescribeRecommendations",
            "rds:DescribeTenantDatabases",
            "rds:DisableHttpEndpoint",
            "rds:EnableHttpEndpoint",
            "rds:ListTagsForResource",
            "rds:ModifyCustomDBEngineVersion",
            "rds:ModifyDBCluster",
            "rds:ModifyDBInstance",
            "rds:ModifyDBShardGroup",
            "rds:ModifyIntegration",
            "rds:ModifyRecommendation",
            "rds:Promote*",
            "rds:RebootDBInstance",
            "rds:RebootDBShardGroup",
            "rds:RemoveTagsFromResource"
          ],
          resources = [
            "*"
          ]
        },
      ]
    },
    {
      policy_name        = "DWAdmin4"
      policy_description = "Policy 4 for DWAdmin role"
      policy_document = [

        {
          sid    = "Redshift"
          effect = "Allow"
          actions = [
            "redshift:ViewQueriesInConsole",
            "redshift:ViewQueriesFromConsole",
            "redshift:ModifySavedQuery",
            "redshift:List*",
            "redshift:FetchResults",
            "redshift:ExecuteQuery",
            "redshift:DescribeClusterDbRevisions",
            "redshift:DescribeClusterParameterGroups",
            "redshift:DescribeClusterParameters",
            "redshift:DescribeClusters",
            "redshift:DescribeClusterSnapshots",
            "redshift:DescribeClusterSubnetGroups",
            "redshift:DescribeDataSharesFor*",
            "redshift:DescribeEndpointAuthorization",
            "redshift:DescribeEvents",
            "redshift:DescribeHsm*",
            "redshift:DescribeLoggingStatus",
            "redshift:DescribePartners",
            "redshift:DescribeQev2IdcApplications",
            "redshift:DescribeQuery",
            "redshift:DescribeRedshiftIdcApplications",
            "redshift:DescribeReservedNodes",
            "redshift:DescribeSavedQueries",
            "redshift:DescribeScheduledActions",
            "redshift:DescribeTable*",
            "redshift:DescribeTags",
            "redshift:DescribeUsageLimits",
            "redshift:DeleteTags",
            "redshift:DeleteSavedQueries",
            "redshift:CreateTags",
            "redshift:CreateSavedQuery",
            "redshift:CancelQuerySession",
            "redshift:CancelQuery",
            "redshift:RebootCluster",
            "redshift-serverless:ListWorkgroups",
            "redshift-serverless:ListNamespaces"
          ],
          resources = [
            "*"
          ]
        },
        {
          sid    = "RedshiftQueryExecution"
          effect = "Allow"
          actions = [
            "redshift:ViewQueriesFromConsole",
            "redshift:ModifySavedQuery",
            "redshift:FetchResults",
            "redshift:ExecuteQuery",
            "redshift:DeleteSavedQueries",
            "redshift:CreateSavedQuery"
          ],
          resources = [
            "*"
          ]
        },
        {
          sid    = "Route53"
          effect = "Allow"
          actions = [
            "route53:GetHostedZone",
            "route53:ListResourceRecordSets",
            "route53:ListTags*",
            "route53resolver:ListFirewallRuleGroupAssociations",
            "route53resolver:ListTagsForResource"
          ],
          resources = [
            "*"
          ]
        },
        {
          sid    = "S3"
          effect = "Allow"
          actions = [
            "s3:AbortMultipartUpload",
            "s3:BypassGovernanceRetention",
            "s3:CreateStorageLensGroup",
            "s3:DeleteJobTagging",
            "s3:DeleteObject*",
            "s3:DeleteStorageLensConfigurationTagging",
            "s3:DeleteStorageLensGroup",
            "s3:GetAccelerateConfiguration",
            "s3:GetAccountPublicAccessBlock",
            "s3:GetBucketAcl",
            "s3:GetBucketCORS",
            "s3:GetBucketLocation",
            "s3:GetBucketLogging",
            "s3:GetBucketNotification",
            "s3:GetBucketObjectLockConfiguration",
            "s3:GetBucketOwnershipControls",
            "s3:GetBucketPolicy",
            "s3:GetBucketPublicAccessBlock",
            "s3:GetBucketRequestPayment",
            "s3:GetBucketTagging",
            "s3:GetBucketVersioning",
            "s3:GetBucketWebsite",
            "s3:GetEncryptionConfiguration",
            "s3:GetInventoryConfiguration",
            "s3:GetJobTagging",
            "s3:GetLifecycleConfiguration",
            "s3:GetObject",
            "s3:GetObjectAcl",
            "s3:GetObjectLegalHold",
            "s3:GetObjectRetention",
            "s3:GetObjectTagging",
            "s3:GetObjectTorrent",
            "s3:GetObjectVersion*",
            "s3:GetReplicationConfiguration",
            "s3:GetStorage*",
            "s3:InitiateReplication",
            "s3:ListAllMyBuckets",
            "s3:ListBucket",
            "s3:ListBucketVersions",
            "s3:ListCallerAccessGrants",
            "s3:ListMultipartUploadParts",
            "s3:ListStorageLensGroups",
            "s3:ListTagsForResource",
            "s3:ObjectOwnerOverrideToBucketOwner",
            "s3:PauseReplication",
            "s3:PutAccessPointPublicAccessBlock",
            "s3:PutBucketNotification",
            "s3:PutBucketTagging",
            "s3:PutJobTagging",
            "s3:PutObject*",
            "s3:PutStorageLensConfigurationTagging",
            "s3:Replicate*",
            "s3:RestoreObject",
            "s3:TagResource",
            "s3:UntagResource",
            "s3:UpdateStorageLensGroup"
          ],
          resources = [
            "*"
          ]
        },
        {
          sid    = "SNS"
          effect = "Allow"
          actions = [
            "sns:*"
          ],
          resources = [
            "*"
          ]
        },
        {
          sid    = "SSM"
          effect = "Allow"
          actions = [
            "ssm:AddTagsToResource",
            "ssm:DescribeDocument",
            "ssm:DescribeDocumentPermission",
            "ssm:DescribeInstanceInformation",
            "ssm:DescribeParameters",
            "ssm:GetCalendar",
            "ssm:GetDocument",
            "ssm:GetManifest",
            "ssm:GetParameter",
            "ssm:ListTagsForResource",
            "ssm:PutCalendar",
            "ssm:PutConfigurePackageResult",
            "ssm:RemoveTagsFromResource",
            "ssm:StartSession",
            "ssm:TerminateSession",
            "ssm:UpdateInstanceAssociationStatus"
          ],
          resources = [
            "*"
          ]
        },

        {
          sid    = "SecretsManager"
          effect = "Allow"
          actions = [
            "secretsmanager:CreateSecret",
            "secretsmanager:DeleteSecret",
            "secretsmanager:DescribeSecret",
            "secretsmanager:Get*",
            "secretsmanager:ListSecrets",
            "secretsmanager:ListSecretVersionIds",
            "secretsmanager:TagResource"
          ],
          resources = [
            "*"
          ]
        },
        {
          sid    = "Support"
          effect = "Allow"
          actions = [
            "support:*"
          ],
          resources = [
            "*"
          ]
        },
        {
          sid    = "Tag"
          effect = "Allow"
          actions = [
            "tag:GetResources",
            "tag:GetTag*",
            "tag:TagResources",
            "tag:UntagResources"
          ],
          resources = [
            "*"
          ]
        },
        {
          sid    = "XRay"
          effect = "Allow"
          actions = [
            "xray:Batch*",
            "xray:GetDistinctTraceGraphs",
            "xray:GetGroups",
            "xray:GetInsightSummaries",
            "xray:GetSamplingStatisticSummaries",
            "xray:GetSamplingTargets",
            "xray:GetServiceGraph",
            "xray:GetTimeSeriesServiceStatistics",
            "xray:GetTrace*",
            "xray:Link",
            "xray:ListTagsForResource",
            "xray:PutTelemetryRecords",
            "xray:PutTraceSegments",
            "xray:TagResource",
            "xray:UntagResource"
          ],
          resources = [
            "*"
          ]
        }
      ]

    },
  ]
}

data "aws_iam_policy_document" "dwadmin_redshift_access" {
  count = module.dwadmin-assumerole != null && contains(local.enabled_roles, "iam_dwadmin_enabled") ? 1 : 0
  statement {
    sid    = "RedshiftUserAccess"
    effect = "Allow"
    actions = [
      "redshift:GetClusterCredentials",
    ]
    resources = [
      "arn:aws:redshift:us-west-2:*:cluster:*",
      "arn:aws:redshift:us-west-2:*:dbname:*/analytics",
      "arn:aws:redshift:us-west-2:*:dbuser:*/$${redshift:DbUser}"
    ]
    condition {
      test     = "StringEqualsIgnoreCase"
      variable = "aws:userid"
      values = [
        "${module.dwadmin-assumerole.iam_assumable_role.unique_id}:$${redshift:DbUser}",
      ]
    }
  }
}

resource "aws_iam_policy" "dwadmin_redshift_access" {
  count  = module.dwadmin-assumerole != null && contains(local.enabled_roles, "iam_dwadmin_enabled") ? 1 : 0
  name   = "DWAdminDataWarehouseAccess"
  policy = data.aws_iam_policy_document.dwadmin_redshift_access[0].json
}

resource "aws_iam_role_policy_attachment" "dwadmin_redshift_access" {
  count      = module.dwadmin-assumerole != null && contains(local.enabled_roles, "iam_dwadmin_enabled") ? 1 : 0
  role       = module.dwadmin-assumerole.iam_assumable_role.name
  policy_arn = aws_iam_policy.dwadmin_redshift_access[0].arn
}
