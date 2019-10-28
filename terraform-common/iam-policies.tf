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
            test = "StringNotEquals"
            variable = "aws:RequestedRegion"
            values = [
                "us-west-2",
                "us-east-1"
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
        resources = [
            "*"
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
        resources = [
            "*"
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
        sid = "SQS"
        effect = "Allow"
        actions = [
            "sqs:*"
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

# read only policy
resource "aws_iam_policy" "readonly1" {
    name = "ReadOnly1"
    path = "/"
    description = "Read only permissions"
    policy = "${data.aws_iam_policy_document.readonly1.json}"
}

data "aws_iam_policy_document" "readonly1"  {
    statement {
        sid = "ReadOnly1"
        effect = "Allow"
        actions = [
            "acm:Describe*",
            "acm:List*",
            "acm:Get*",
            "acm-pca:List*",
            "acm-pca:Describe*",
            "acm-pca:Get*",
            "application-autoscaling:Describe*",
            "athena:List*",
            "athena:Batch*",
            "athena:Get*",
            "autoscaling:Describe*",
            "batch:Describe*",
            "batch:List*",
            "billing:View*",
            "budget:View*",
            "cloud9:Describe*",
            "cloud9:List*",
            "cloudformation:List*",
            "cloudformation:Describe*",
            "cloudformation:Detect*",
            "cloudformation:Get*",
            "cloudfront:Get*",
            "cloudfront:List*",
            "cloudhsm:List*",
            "cloudhsm:Describe*",
            "cloudhsm:Get*",
            "cloudtrail:Describe*",
            "cloudtrail:Get*",
            "cloudtrail:List*",
            "cloudtrail:LookupEvents",
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
            "codebuild:List*",
            "codebuild:BatchGet*",
            "codecommit:List*",
            "codecommit:BatchGet*",
            "codecommit:CancelUploadArchive",
            "codecommit:Get*",
            "codecommit:GitPull",
            "codedeploy:Get*",
            "codedeploy:List*",
            "codedeploy:BatchGet*",
            "codepipeline:List*",
            "codepipeline:Get*",
            "config:Describe*",
            "config:List*",
            "config:BatchGet*",
            "config:Deliver*",
            "config:Get*",
            "cur:Describe*",
            "ce:Get*",
            "dynamodb:List*",
            "dynamodb:BatchGet*",
            "dynamodb:ConditionCheckItem",
            "dynamodb:Describe*",
            "dynamodb:Get*",
            "dynamodb:Query",
            "dynamodb:Scan",
            "dax:Describe*",
            "dax:BatchGet*",
            "dax:ConditionCheckItem",
            "dax:Get*",
            "dax:List*",
            "dax:Query",
            "dax:Scan",
            "ec2:Describe*",
            "ec2:ExportClientVpn*",
            "ec2:Get*",
            "ec2:SearchTransitGatewayRoutes",
            "ec2messages:Get*",
            "eks:List*",
            "eks:Describe*",
            "ecr:Describe*",
            "ecr:BatchGet*",
            "ecr:Get*",
            "ecr:BatchCheckLayerAvailability",
            "ecr:List*",
            "ecs:List*",
            "ecs:Describe*",
            "elasticache:Describe*",
            "elasticache:List*",
            "elasticloadbalancing:Describe*",
            "glacier:List*",
            "glacier:Describe*",
            "glacier:Get*",
            "glue:Get*",
            "glue:BatchGet*",
            "guardduty:List*",
            "guardduty:Get*",
            "health:Describe*",
            "iam:Get*",
            "iam:List*",
            "iam:Simulate*",
            "inspector:List*",
            "inspector:PreviewAgents",
            "inspector:Get*"
        ]
        resources = [
            "*"
        ]
    }
}

resource "aws_iam_policy" "readonly2" {
    name = "ReadOnly2"
    path = "/"
    description = "Read only permissions"
    policy = "${data.aws_iam_policy_document.readonly2.json}"
}

data "aws_iam_policy_document" "readonly2"  {
    statement {
        sid = "ReadOnly2"
        effect = "Allow"
        actions = [
            "kinesis:List*",
            "kinesis:Describe*",
            "kinesis:Get*",
            "kinesis:SubscribeToShard",
            "kinesisanalytics:List*",
            "kinesisanalytics:DescribeApplication",
            "kinesisanalytics:DiscoverInputSchema",
            "kms:List*",
            "kms:DescribeKey",
            "kms:Get*",
            "lambda:List*",
            "lambda:Get*",
            "macie:List*",
            "organizations:List*",
            "organizations:Describe*",
            "pinpoint:Get*",
            "pinpoint:List*",
            "pinpoint:PhoneNumberValidate",
            "ses:List*",
            "ses:Get*",
            "ses:Verify*",
            "sms-voice:GetConfiguration*",
            "sms-voice:List*",
            "quicksight:List*",
            "quicksight:Describe*",
            "quicksight:GetDashboardEmbedUrl",
            "quicksight:GetGroupMapping",
            "rds:Describe*",
            "rds:List*",
            "redshift:Describe*",
            "redshift:ViewQueries*",
            "redshift:List*",
            "redshift:FetchResults",
            "redshift:GetReservedNodeExchangeOfferings",
            "ram:List*",
            "tag:Get*",
            "resource-groups:List*",
            "resource-groups:SearchResources",
            "resource-groups:Get*",
            "route53:Get*",
            "route53:List*",
            "route53:TestDNSAnswer",
            "route53resolver:List*",
            "route53resolver:Get*",
            "route53domains:List*",
            "route53domains:CheckDomainAvailability",
            "route53domains:ViewBilling",
            "route53domains:Get*",
            "s3:HeadBucket",
            "s3:List*",
            "s3:Get*",
            "secretsmanager:ListSecrets",
            "secretsmanager:DescribeSecret",
            "secretsmanager:Get*",
            "secretsmanager:ListSecretVersionIds",
            "securityhub:Get*",
            "securityhub:List*",
            "serverlessrepo:List*",
            "serverlessrepo:Get*",
            "serverlessrepo:SearchApplications",
            "shield:List*",
            "shield:Describe*",
            "shield:GetSubscriptionState",
            "sns:List*",
            "sns:CheckIfPhoneNumberIsOptedOut",
            "sns:Get*",
            "sqs:List*",
            "sqs:Get*",
            "states:List*",
            "states:Describe*",
            "states:Get*",
            "sts:Get*",
            "support:Describe*",
            "ssm:Describe*",
            "ssm:List*",
            "ssm:Get*",
            "ssm:PutConfigurePackageResult",
            "trustedadvisor:Describe*",
            "waf:List*",
            "waf:Get*",
            "waf-regional:List*",
            "waf-regional:Get*",
            "xray:BatchGetTraces",
            "xray:Get*"
        ]
        resources = [
            "*"
        ]
    }
}
