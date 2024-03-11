################################################################################
# EKS Blueprints Addons
# Using GitOps Bridge so only creating IRSA
# https://github.com/aws-ia/terraform-aws-eks-blueprints-addons
################################################################################
module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  cluster_name      = module.eks_cluster.cluster_name
  cluster_endpoint  = module.eks_cluster.cluster_endpoint
  cluster_version   = module.eks_cluster.cluster_version
  oidc_provider_arn = module.eks_cluster.oidc_provider_arn

  # Using GitOps Bridge
  create_kubernetes_resources = false

  # EKS Blueprints Addons
  enable_cluster_autoscaler           = true
  enable_external_dns                 = true
  enable_aws_load_balancer_controller = true
  enable_cert_manager                 = true
  external_dns_route53_zone_arns      = [aws_route53_zone.selected.arn, aws_route53_zone.pivcac.arn]
  enable_metrics_server               = true

  tags = local.tags
}