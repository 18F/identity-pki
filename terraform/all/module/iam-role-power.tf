module "poweruser-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=995040426241ec92a1eccb391d32574ad5fc41be"
  #source = "../../../../identity-terraform/iam_assumerole"

  role_name                       = "PowerUser"
  enabled                         = contains(local.enabled_roles, "iam_power_enabled")
  master_assumerole_policy        = data.aws_iam_policy_document.master_account_assumerole.json
  custom_iam_policies             = var.dnssec_zone_exists ? [data.aws_iam_policy.dnssec_disable_prevent[0].name] : []
  permissions_boundary_policy_arn = aws_iam_policy.permissions_boundary.arn

  iam_policies = [
    {
      policy_name        = "Power1"
      policy_description = "Policy 1 for Power User"
      policy_document = [
        {
          sid    = "AccessAnalyzer"
          effect = "Allow"
          actions = [
            "access-analyzer:GetAnalyzer",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "Athena"
          effect = "Allow"
          actions = [
            "athena:*",
            "glue:*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "AthenaKMSKeyAccess"
          effect = "Allow"
          actions = [
            "kms:Decrypt",
            "kms:DescribeKey",
            "kms:Encrypt",
            "kms:GenerateDataKey",
          ]
          resources = [
            "*"
          ]
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
            "autoscaling:*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "CloudFormation"
          effect = "Allow"
          actions = [
            "cloudformation:*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "CloudFront"
          effect = "Allow"
          # Create, list, get, and limited delete without deleting a whole distribution
          actions = [
            "cloudfront:CreateCloudFrontOriginAccessIdentity",
            "cloudfront:CreateDistribution",
            "cloudfront:CreateInvalidation",
            "cloudfront:DeleteCloudFrontOriginAccessIdentity",
            "cloudfront:GetCachePolicy",
            "cloudfront:GetDistribution",
            "cloudfront:GetCloudFrontOriginAccessIdentity",
            "cloudfront:GetCloudFrontOriginAccessIdentityConfig",
            "cloudfront:GetInvalidation",
            "cloudfront:ListDistributions",
            "cloudfront:ListFieldLevelEncryptionConfigs",
            "cloudfront:ListInvalidations",
            "cloudfront:ListCloudFrontOriginAccessIdentities",
            "cloudfront:ListStreamingDistributions",
            "cloudfront:ListTagsForResource",
            "cloudfront:TagResource",
            "cloudfront:UpdateCloudFrontOriginAccessIdentity",
            "cloudfront:UpdateDistribution",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "CloudWatch"
          effect = "Allow"
          actions = [
            "cloudwatch:*",
            "logs:*",
            "events:*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "CodeStar"
          effect = "Allow"
          actions = [
            "codestar-notifications:DescribeNotificationRule",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "Config"
          effect = "Allow"
          actions = [
            "config:DescribeConfigurationRecorders",
            "config:DescribeConfigurationRecorderStatus",
            "config:DescribeDeliveryChannels",
            "config:DescribeRemediationConfigurations",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "DynamoDb"
          effect = "Allow"
          actions = [
            "dynamodb:*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "Firehose"
          effect = "Allow"
          actions = [
            "firehose:*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "IAM"
          effect = "Allow"
          actions = [
            "iam:List*",
            "iam:Get*",
            "iam:GenerateServiceLastAccessedDetails",
            "iam:RemoveRoleFromInstanceProfile",
            "iam:CreateRole",
            "iam:CreatePolicyVersion",
            "iam:DeletePolicyVersion",
            "iam:AttachRolePolicy",
            "iam:PutRolePolicy",
            "iam:AddRoleToInstanceProfile",
            "iam:DetachRolePolicy",
            "iam:DeleteServerCertificate",
            "iam:DetachUserPolicy", # remove?
            "iam:AttachUserPolicy", # remove?
            "iam:DeleteRole",
            "iam:GenerateCredentialReport",
            "iam:CreateInstanceProfile",
            "iam:DeletePolicy",
            "iam:PassRole",
            "iam:DeleteRolePolicy",
            "iam:DeleteInstanceProfile",
            "iam:Tag*",
            "iam:Untag*",
            "iam:UploadServerCertificate",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "Kinesis"
          effect = "Allow"
          actions = [
            "kinesis:*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "KMS"
          effect = "Allow"
          actions = [
            "kms:ListResourceTags",
            "kms:GetKeyRotationStatus",
            "kms:DisableKey",
            "kms:DisableKeyRotation",
            "kms:DeleteAlias",
            "kms:PutKeyPolicy",
            "kms:TagResource",
            "kms:ScheduleKeyDeletion",
            "kms:DescribeKey",
            "kms:CreateKey",
            "kms:EnableKeyRotation",
            "kms:ListKeyPolicies",
            "kms:UpdateKeyDescription",
            "kms:GetKeyPolicy",
            "kms:UpdateAlias",
            "kms:ListKeys",
            "kms:ListAliases",
            "kms:CreateAlias",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "NetworkFirewall"
          effect = "Allow"
          actions = [
            "network-firewall:DescribeRuleGroup",
            "network-firewall:DescribeFirewall",
            "network-firewall:DescribeFirewallPolicy",
            "network-firewall:DescribeLoggingConfiguration",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "Pinpoint"
          effect = "Allow"
          actions = [
            "mobiletargeting:Get*",
            "mobiletargeting:List*",
            "mobiletargeting:SendMessages",
            "pinpoint:Get*",
            "pinpoint:List*",
            "pinpoint:PhoneNumberValidate",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "RDS"
          effect = "Allow"
          actions = [
            "pi:*",
            "rds:*",
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
            "route53:UpdateHostedZoneComment",
            "route53:CreateHostedZone",
            "route53:ChangeResourceRecordSets",
            "route53:DeleteHostedZone",
            "route53:TestDNSAnswer",
            "route53domains:Get*",
            "route53domains:List*",
            "route53resolver:Get*",
            "route53resolver:List*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "SNS"
          effect = "Allow"
          actions = [
            "sns:*",
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
      ]
    },
    {
      policy_name        = "Power2"
      policy_description = "Policy 2 for Power User"
      policy_document = [
        {
          sid    = "ACM"
          effect = "Allow"
          actions = [
            "acm:DescribeCertificate",
            "acm:ListCertificates",
            "acm:ListTagsForCertificate",
            "acm:RequestCertificate",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "CloudHSM"
          effect = "Allow"
          actions = [
            "cloudhsm:*",
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
            "cloudtrail:GetEventSelectors",
            "cloudtrail:GetTrailStatus",
            "cloudtrail:ListTags",
            "cloudtrail:LookupEvents",
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
            "codedeploy:*"
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "GuardDuty"
          effect = "Allow"
          actions = [
            "guardduty:*",
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
            "ec2:AcceptVpcPeeringConnection",
            "ec2:AllocateAddress",
            "ec2:AssignPrivateIpAddresses",
            "ec2:AssociateAddress",
            "ec2:AssociateDhcpOptions",
            "ec2:AssociateIamInstanceProfile",
            "ec2:AssociateRouteTable",
            "ec2:AssociateVpcCidrBlock",
            "ec2:AttachInternetGateway",
            "ec2:AttachNetworkInterface",
            "ec2:AttachVolume",
            "ec2:AuthorizeSecurityGroupEgress",
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:CopyImage",
            "ec2:CreateDhcpOptions",
            "ec2:CreateFlowLogs",
            "ec2:CreateImage",
            "ec2:CreateInternetGateway",
            "ec2:CreateLaunchTemplate",
            "ec2:CreateLaunchTemplateVersion",
            "ec2:CreateKeyPair",
            "ec2:CreateNatGateway",
            "ec2:CreateNetworkAcl",
            "ec2:CreateNetworkAclEntry",
            "ec2:CreateNetworkInterface",
            "ec2:CreateRoute",
            "ec2:CreateRouteTable",
            "ec2:CreateSecurityGroup",
            "ec2:CreateSnapshot",
            "ec2:CreateSubnet",
            "ec2:CreateTags",
            "ec2:CreateVpc",
            "ec2:CreateVpcEndpoint",
            "ec2:DeleteDhcpOptions",
            "ec2:DeleteFlowLogs",
            "ec2:DeleteInternetGateway",
            "ec2:DeleteLaunchTemplate",
            "ec2:DeleteLaunchTemplateVersion",
            "ec2:DeleteKeyPair",
            "ec2:DeleteN*", #should a user be able to delete resources they cannot create?
            "ec2:DeleteRoute",
            "ec2:DeleteRouteTable",
            "ec2:DeleteS*", #should a user be able to delete resources they cannot create?
            "ec2:DeleteTags",
            "ec2:DeleteVpc",
            "ec2:DeleteVpcEndpoints",
            "ec2:DeregisterImage",
            "ec2:DetachInternetGateway",
            "ec2:DetachNetworkInterface",
            "ec2:DetachVolume",
            "ec2:DetachVpnGateway",           #don't use vpn seems unnecessary
            "ec2:DisableVgwRoutePropagation", #don't use vpn seems unnecessary
            "ec2:DisassociateAddress",
            "ec2:DisassociateRouteTable",
            "ec2:DisassociateIamInstanceProfile",
            "ec2:DisassociateVpcCidrBlock",
            "ec2:EnableVgwRoutePropagation", #don't use vpn seems unnecessary
            "ec2:GetConsoleScreenshot",
            "ec2:GetConsoleOutput",
            "ec2:ImportInstance",
            "ec2:ImportKeyPair",
            "ec2:ModifyImageAttribute",
            "ec2:ModifyInstanceAttribute",
            "ec2:ModifyLaunchTemplate",
            "ec2:ModifyNetworkInterfaceAttribute",
            "ec2:ModifySubnetAttribute",
            "ec2:ModifyVpcAttribute",
            "ec2:ModifyVpcEndpoint",
            "ec2:MonitorInstances",
            "ec2:MoveAddressToVpc",
            "ec2:RejectVpcPeeringConnection",
            "ec2:ReleaseAddress",
            "ec2:ReplaceIamInstanceProfileAssociation",
            "ec2:ReplaceNetworkAclAssociation",
            "ec2:ReplaceNetworkAclEntry",
            "ec2:ReplaceRoute",
            "ec2:ReplaceRouteTableAssociation",
            "ec2:ResetNetworkInterfaceAttribute",
            "ec2:RevokeSecurityGroupEgress",
            "ec2:RevokeSecurityGroupIngress",
            "ec2:RunInstances",
            "ec2:StartInstances",
            "ec2:StopInstances",
            "ec2:TerminateInstances",
            "ec2:UnassignPrivateIpAddresses",
            "ec2:UnmonitorInstances",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "ElasticCache"
          effect = "Allow"
          actions = [
            "elasticache:*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "ELB"
          effect = "Allow"
          actions = [
            "elasticloadbalancing:AddListenerCertificates",
            "elasticloadbalancing:RemoveListenerCertificates",
            "elasticloadbalancing:AddTags",
            "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
            "elasticloadbalancing:AttachLoadBalancerToSubnets",
            "elasticloadbalancing:CreateListener",
            "elasticloadbalancing:ConfigureHealthCheck",
            "elasticloadbalancing:CreateLoadBalancer",
            "elasticloadbalancing:CreateLoadBalancerListeners",
            "elasticloadbalancing:CreateRule",
            "elasticloadbalancing:CreateTargetGroup",
            "elasticloadbalancing:DeleteListener",
            "elasticloadbalancing:DeleteLoadBalancer",
            "elasticloadbalancing:DeleteRule",
            "elasticloadbalancing:DeleteTargetGroup",
            "elasticloadbalancing:DeregisterTargets",
            "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
            "elasticloadbalancing:Describe*",
            "elasticloadbalancing:ModifyLoadBalancerAttributes",
            "elasticloadbalancing:ModifyTargetGroup",
            "elasticloadbalancing:ModifyTargetGroupAttributes",
            "elasticloadbalancing:ModifyListener",
            "elasticloadbalancing:ModifyRule",
            "elasticloadbalancing:RegisterTargets",
            "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
            "elasticloadbalancing:SetSecurityGroups",
            "elasticloadbalancing:SetSubnets",
            "elasticloadbalancing:DescribeSSLPolicies",
            "elasticloadbalancing:SetIpAddressType",
            "elasticloadbalancing:SetRulePriorities",
            "elasticloadbalancing:SetWebACL",
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
          sid    = "Macie"
          effect = "Allow"
          actions = [
            "macie:*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "Macie2"
          effect = "Allow"
          actions = [
            "macie2:*",
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
            "ses:*",
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
          sid    = "SQS"
          effect = "Allow"
          actions = [
            "sqs:*",
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
          sid    = "Support"
          effect = "Allow"
          actions = [
            "support:*",
          ]
          resources = [
            "*",
          ]
        },
        {
          # Full access to tagging - Used minimally at this time
          sid    = "Tag"
          effect = "Allow"
          actions = [
            "tag:*"
          ]
          resources = [
            "*"
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
          sid    = "WAFv2"
          effect = "Allow"
          actions = [
            "wafv2:*",
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
            "ecr:GetLifecyclePolicy",
            "ecr:GetLifecyclePolicyPreview",
            "ecr:GetRegistryPolicy",
            "ecr:GetRepositoryPolicy",
            "ecr:List*",
          ]
          resources = [
            "*",
          ]
        }
      ]
    },
    {
      policy_name        = "Power3"
      policy_description = "Policy 3 for Power User"
      policy_document = [
        {
          sid    = "DMS"
          effect = "Allow"
          actions = [
            "dms:Describe*",
            "dms:List*",
            "dms:AddTagsToResource",
            "dms:ApplyPendingMaintenanceAction",
            "dms:AssociateExtensionPack",
            "dms:CancelReplicationTaskAssessmentRun",
            "dms:CreateReplicationTask",
            "dms:DeleteReplicationTask",
            "dms:DeleteReplicationTaskAssessmentRun",
            "dms:ModifyReplicationTask",
            "dms:MoveReplicationTask",
            "dms:RebootReplicationInstance",
            "dms:RefreshSchemas",
            "dms:ReloadReplicationTables",
            "dms:ReloadTables",
            "dms:RemoveTagsFromResource",
            "dms:StartDataMigration",
            "dms:StartReplication",
            "dms:StartReplicationTask",
            "dms:StartReplicationTaskAssessment",
            "dms:StartReplicationTaskAssessmentRun",
            "dms:StopDataMigration",
            "dms:StopReplication",
            "dms:StopReplicationTask",
            "dms:TestConnection",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "IncidentManager",
          effect = "Allow",
          actions = [
            "ssm-incidents:ListIncidentFindings",
            "ssm-incidents:ListIncidentRecords",
            "ssm-incidents:ListRelatedItems",
            "ssm-incidents:ListReplicationSets",
            "ssm-incidents:ListResponsePlans",
            "ssm-incidents:ListTimelineEvents",
            "ssm-incidents:BatchGetIncidentFindings",
            "ssm-incidents:GetIncidentRecord",
            "ssm-incidents:GetReplicationSet",
            "ssm-incidents:GetResourcePolicies",
            "ssm-incidents:GetResponsePlan",
            "ssm-incidents:GetTimelineEvent",
            "ssm-incidents:ListTagsForResource",
            "ssm-incidents:CreateResponsePlan",
            "ssm-incidents:CreateTimelineEvent",
            "ssm-incidents:DeleteResponsePlan",
            "ssm-incidents:DeleteTimelineEvent",
            "ssm-incidents:StartIncident",
            "ssm-incidents:UpdateIncidentRecord",
            "ssm-incidents:UpdateRelatedItems",
            "ssm-incidents:UpdateReplicationSet",
            "ssm-incidents:UpdateResponsePlan",
            "ssm-incidents:UpdateTimelineEvent",
            "ssm-incidents:TagResource",
            "ssm-incidents:UntagResource",
            "ssm-contacts:ListContactChannels",
            "ssm-contacts:ListContacts",
            "ssm-contacts:ListEngagements",
            "ssm-contacts:ListPageReceipts",
            "ssm-contacts:ListPageResolutions",
            "ssm-contacts:ListPagesByContact",
            "ssm-contacts:ListPagesByEngagement",
            "ssm-contacts:ListPreviewRotationShifts",
            "ssm-contacts:ListRotationOverrides",
            "ssm-contacts:ListRotations",
            "ssm-contacts:ListRotationShifts",
            "ssm-contacts:DescribeEngagement",
            "ssm-contacts:DescribePage",
            "ssm-contacts:GetContact",
            "ssm-contacts:GetContactChannel",
            "ssm-contacts:GetContactPolicy",
            "ssm-contacts:GetRotation",
            "ssm-contacts:GetRotationOverride",
            "ssm-contacts:ListTagsForResource",
            "ssm-contacts:AcceptPage",
            "ssm-contacts:ActivateContactChannel",
            "ssm-contacts:CreateContactChannel",
            "ssm-contacts:CreateRotationOverride",
            "ssm-contacts:DeactivateContactChannel",
            "ssm-contacts:DeleteContactChannel",
            "ssm-contacts:DeleteRotationOverride",
            "ssm-contacts:SendActivationCode",
            "ssm-contacts:StartEngagement",
            "ssm-contacts:StopEngagement",
            "ssm-contacts:UpdateContact",
            "ssm-contacts:UpdateContactChannel",
            "ssm-contacts:UpdateRotation",
            "ssm-contacts:AssociateContact",
            "ssm-contacts:TagResource",
            "ssm-contacts:UntagResource"
          ],
          resources = [
            "*"
          ]
        }
      ]
    },
    {
      policy_name        = "Power4"
      policy_description = "Policy 4 for Power User"
      policy_document = [
        {
          sid    = "EKS"
          effect = "Allow"
          actions = [
            "eks:DescribeAccessEntry",
            "eks:DescribeAddon",
            "eks:DescribeAddonConfiguration",
            "eks:DescribeAddonVersions",
            "eks:DescribeCluster",
            "eks:DescribeIdentityProviderConfig",
            "eks:DescribeInsight",
            "eks:DescribeNodegroup",
            "eks:DescribePodIdentityAssociation",
            "eks:DescribeUpdate",
            "eks:ListAccessEntries",
            "eks:ListAccessPolicies",
            "eks:ListAddons",
            "eks:ListAssociatedAccessPolicies",
            "eks:ListClusters",
            "eks:ListIdentityProviderConfigs",
            "eks:ListInsights",
            "eks:ListNodegroups",
            "eks:ListPodIdentityAssociations",
            "eks:ListTagsForResource",
            "eks:ListUpdates"
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
            "secretsmanager:ListSecretVersionIds",
          ]
          resources = [
            "*",
          ]
        },

      ]
    }
  ]
}
