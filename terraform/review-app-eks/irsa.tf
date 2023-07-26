# https://github.com/terraform-aws-modules/terraform-aws-iam/tree/v5.20.0/modules/iam-role-for-service-accounts-eks
module "fluentbit_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name   = "${var.cluster_name}-fluentbit"
  create_role = true
  role_policy_arns = {
    policy = aws_iam_policy.eks-aws-fluent-bit.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.review_app.eks_oidc_provider_arn
      namespace_service_accounts = ["logging:aws-for-fluent-bit"]
    }
  }

  tags = {
    Environment = var.cluster_name
    Terraform   = "true"
  }
}

resource "aws_iam_policy" "eks-aws-fluent-bit" {
  name   = "${var.cluster_name}-aws-fluent-bit"
  policy = data.aws_iam_policy_document.aws_fluent_bit.json
}

data "aws_iam_policy_document" "aws_fluent_bit" {
  statement {
    effect = "Allow"

    actions = [
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }
}

## setup  for Fluentd
# https://github.com/terraform-aws-modules/terraform-aws-iam/tree/v5.20.0/modules/iam-role-for-service-accounts-eks
module "fluentd_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name   = "${var.cluster_name}-fluentd"
  create_role = true
  role_policy_arns = {
    policy = aws_iam_policy.eks-fluentd.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.review_app.eks_oidc_provider_arn
      namespace_service_accounts = ["logging:fluentd"]
    }
  }

  tags = {
    Environment = var.cluster_name
    Terraform   = "true"
  }
}

resource "aws_iam_policy" "eks-fluentd" {
  name   = "${var.cluster_name}-fluentd"
  policy = data.aws_iam_policy_document.fluentd.json
}

data "aws_iam_policy_document" "fluentd" {
  statement {
    effect = "Allow"

    actions = [
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "ingress_nginx_policy" {
  statement {
    effect = "Allow"
    actions = [
      "acm:DescribeCertificate",
      "acm:ListCertificates",
      "acm:GetCertificate",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:DeleteSecurityGroup",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeTags",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancerPolicies",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:SetLoadBalancerPoliciesOfListener",
      "elasticloadbalancing:RemoveTags",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:DescribeTags",
      "iam:CreateServiceLinkedRole",
      "iam:PutRolePolicy"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ingress_nginx_policy" {
  name        = "${var.cluster_name}_nginx_ingress_policy"
  description = "IAM policy for NGINX Ingress in the ${var.cluster_name} EKS cluster"
  policy      = data.aws_iam_policy_document.ingress_nginx_policy.json
}

module "ingress_nginx_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name   = "${var.cluster_name}-nginx-ingress"
  create_role = true
  role_policy_arns = {
    policy = aws_iam_policy.ingress_nginx_policy.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.review_app.eks_oidc_provider_arn
      namespace_service_accounts = ["ingress-nginx:ingress-nginx"]
    }
  }

  tags = {
    Environment = var.cluster_name
    Terraform   = "true"
  }
}
