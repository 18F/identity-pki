module "poweruser-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=master"

  role_name                = "PowerUser"
  enabled                  = var.iam_power_enabled
  master_assumerole_policy = local.master_assumerole_policy
  custom_policy_arns       = local.custom_policy_arns

  iam_policies = [
    {
      policy_name        = "Power1"
      policy_description = "Policy 1 for Power User"
      policy_document    = [
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
            "cloudwatch:*",
            "logs:*",
            "events:*",
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
            "iam:UploadServerCertificate",
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
            "cloudfront:ListStreamingDistributions",
            "cloudfront:CreateDistribution",
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
          sid    = "RDS"
          effect = "Allow"
          actions = [
            "rds:*",
          ]
          resources = [
            "*",
          ]
        },
        {
          sid    = "Redshift"
          effect = "Allow"
          actions = [
            "redshift:*",
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
      policy_document    = [
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
            "ec2:AcceptVpcPeeringConnection",
            "ec2:AllocateAddress",
            "ec2:AssignPrivateIpAddresses",
            "ec2:AssociateAddress",
            "ec2:AssociateDhcpOptions",
            "ec2:AssociateIamInstanceProfile",
            "ec2:AssociateRouteTable",
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
            "ec2:EnableVgwRoutePropagation", #don't use vpn seems unnecessary
            "ec2:GetConsoleScreenshot",
            "ec2:GetConsoleOutput",
            "ec2:ImportInstance",
            "ec2:ImportKeyPair",
            "ec2:ModifyImageAttribute",
            "ec2:ModifyInstanceAttribute",
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
            "waf:*",
            "waf-regional:*",
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
      ]
    }
  ]
}
