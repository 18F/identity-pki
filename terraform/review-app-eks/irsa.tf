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