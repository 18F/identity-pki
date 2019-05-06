resource "aws_iam_policy" "full_administrator"
{
    name = "FullAdministratorWithMFA"
    path = "/"
    description = "Policy for full administrator with MFA"
    policy = "${data.aws_iam_policy_document.full_administrator.json}"
}

data "aws_iam_policy_document" "full_administrator" {
    statement {
        sid = "FullAdministratorWithMFA"
        effect = "Allow"
        actions = [
            "*"
        ]
        resources = [
            "*"
        ]
        condition = {
            test = "Bool"
            variable = "aws:MultiFactorAuthPresent"
            values = [
                "true"
            ]
        }
    }
}

# this policy is used by all roles
resource "aws_iam_policy" "region_restriction" {
    name = "RegionRestriction"
    path = "/"
    description = "Limit region usage"
    policy = "${data.aws_iam_policy_document.region_restriction.json}"
}

data "aws_iam_policy_document" "region_restriction"  {
    statement {
        sid = "RegionRestriction"
        effect = "Deny"
        actions = [
            "*"
        ]
        resources = [
            "*"
        ]
        condition {
            test = "StringEquals"
            variable = "aws:RequestedRegion"
            values = [
                "us-east-2",
                "us-west-1",
                "ap-northeast-1",
                "ap-northeast-2",
                "ap-south-1",
                "ap-east-1",
                "ap-southeast-1",
                "ap-southeast-2",
                "ca-central-1",
                "cn-north-1",
                "cn-northwest-1",
                "eu-central-1",
                "eu-west-1",
                "eu-west-2",
                "eu-west-3",
                "eu-north-1",
                "sa-east-1"
            ]
        }
    }
}

# this policy is used by all roles
resource "aws_iam_policy" "rds_delete_prevent" {
    name = "RDSDeletePrevent"
    path = "/"
    description = "Prevent deletion of int, staging and prod rds instances"
    policy = "${data.aws_iam_policy_document.rds_delete_prevent.json}"
}

data "aws_iam_policy_document" "rds_delete_prevent" {
    statement {
        sid = "RDSDeletionPrevent"
        effect = "Deny"
        actions = [
            "rds:DeleteDBInstance"
        ]
        resources = [
            "arn:aws:rds:*:*:db:*int*",
            "arn:aws:rds:*:*:db:*staging*",
            "arn:aws:rds:*:*:db:*prod*"
        ]
    }
}

resource "aws_iam_policy" "power1"
{
    name = "Power1"
    path = "/"
    description = "Policy for power with MFA"
    policy = "${data.aws_iam_policy_document.power1.json}"
}

data "aws_iam_policy_document" "power1" {
    statement {
        sid = "Autoscaling"
        effect = "Allow"
        actions = [
            "autoscaling:*"
        ]
        resources = [
            "*"
        ]
    }
    statement {
        sid = "CloudWatch"
        effect = "Allow"
        actions = [
            "cloudwatch:*",
            "logs:*",
            "events:*"
        ]
        resources = [
            "*"
        ]
    }
    statement {
        sid = "SNS"
        effect = "Allow"
        actions = [
            "sns:*"
        ]
        resources = [
            "*"
        ]
    }
    statement {
        sid = "KMS"
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
    }
    statement {
        sid = "IAM"
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
            "iam:UploadServerCertificate"
        ]
    }
    statement {
        sid = "CloudFront"
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
            "cloudfront:CreateDistribution"
        ]
        resources = [
            "*"
        ]
    }
    statement {
        sid = "DynamoDb"
        effect = "Allow"
        actions = [
            "dynamodb:CreateTable",
            "dynamodb:DescribeTable",
            "dynamodb:DeleteItem",
            "dynamodb:CreateTable",
            "dynamodb:DescribeTable",
            "dynamodb:PutItem",
            "dynamodb:GetItem"
        ]
        resources = [
            "*"
        ]
    }
    statement {
        sid = "RDS"
        effect = "Allow"
        actions = [
            "rds:*"
        ]
        resources = [
            "*"
        ]
    }
    statement {
        sid = "Redshift"
        effect = "Allow"
        actions = [
            "redshift:*"
        ]
        resources = [
            "*"
        ]    
    }
    statement {
        sid = "Route53"
        effect = "Allow"
        actions = [
            "route53:GetHostedZone",
            "route53:ListHostedZonesByName",
            "route53:ListResourceRecordSets",
            "route53:UpdateHostedZoneComment",
            "route53:CreateHostedZone",
            "route53:ChangeResourceRecordSets",
            "route53:GetChange",
            "route53:DeleteHostedZone"
        ]
        resources = [
            "*"
        ]
    }
    statement {
        sid = "CloudFormation"
        effect = "Allow"
        actions = [
            "cloudformation:*"
        ]
        resources = [
            "*"
        ]
    }
    statement {
        sid = "STS"
        effect = "Allow"
        actions = [
            "sts:DecodeAuthorizationMessage"
        ]
        resources = [
            "*"
        ]
    }
}
#TODO KMS Delete functionality.  Separate role or limit to environment?

resource "aws_iam_policy" "power2"
{
    name = "Power2"
    path = "/"
    description = "Policy for power"
    policy = "${data.aws_iam_policy_document.power2.json}"
}

data "aws_iam_policy_document" "power2" {
    statement {
        sid = "GuardDuty"
        effect = "Allow"
        actions = [
            "guardduty:*"
        ]
        resources = [
            "*"
        ]
    }
    statement {
        sid = "Support"
        effect = "Allow"
        actions = [
            "support:*"
        ]
        resources = [
            "*"
        ]
    }
    statement {
        sid = "Lambda"
        effect = "Allow"
        actions = [
            "lambda:*"
        ]
        resources = [
            "*"
        ]
    }
    statement {
        sid = "CloudHSM"
        effect = "Allow"
        actions = [
            "cloudhsm:*"
        ]
        resources = [
            "*"
        ]
    }
    statement {
        sid = "Macie"
        effect = "Allow"
        actions = [
            "macie:*"
        ]
        resources = [
            "*"
        ]
    }
    statement {
        sid = "ACM"
        effect = "Allow"
        actions = [
            "acm:DescribeCertificate",
            "acm:ListCertificates",
            "acm:ListTagsForCertificate"
        ]
        resources = [
            "*"
        ]
    }
    statement {
        sid = "CloudTrail"
        effect = "Allow"
        actions = [
            "cloudtrail:DescribeTrails",
            "cloudtrail:GetTrailStatus",
            "cloudtrail:ListTags",
            "cloudtrail:LookupEvents"
        ]
        resources = [
            "*"
        ]
    }
    statement {
        sid = "EC2"
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
            "ec2:DetachVpnGateway",  #don't use vpn seems unnecessary
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
            "ec2:UnmonitorInstances"
        ]
        resources = [
            "*"
        ]
    }
    statement {
        sid = "ElasticCache"
        effect = "Allow"
        actions = [
            "elasticache:*"
        ]
        resources = [
            "*"
        ]
    }
    statement {
        sid = "ELB"
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
            "elasticloadbalancing:SetWebACL"
        ]
        resources = [
            "*"
        ]
    }
    statement {
        sid = "S3"
        effect = "Allow"
        actions = [
            "s3:*"
        ]
        resources = [
            "*"
        ]
    }
    statement {
        sid = "SES"
        effect = "Allow"
        actions = [
            "ses:*"
        ]
        resources = [
            "*"
        ]
    }
    statement {
        sid = "TrustedAdvisor"
        effect = "Allow"
        actions = [
            "trustedadvisor:Describe*"
        ]
        resources = [
            "*"
        ]
    }
    statement {
        sid = "WAF"
        effect = "Allow"
        actions = [
            "waf:*",
            "waf-regional:*"
        ]
        resources = [
            "*"
        ]
    }
}