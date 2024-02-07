# Populates a ssh key for ArgoCD to use to pull repos
module "aws_secrets_to_kubernetes" {
  depends_on = [module.gitops_bridge]
  source     = "../modules/aws_secrets_to_kubernetes"
  key_list = {
    "identity-eks-charts-s3" = {
      source = "s3"
      metadata = {
        name      = "identity-eks-charts-s3"
        s3_bucket = "login-gov.secrets.894947205914-us-west-2"
        s3_key    = "reviewapp/infra-charts-key"
        namespace = "argocd"
        labels = {
          "argocd.argoproj.io/secret-type" = "repository"
        }
      }
      data = {
        "type" = "git"
        "name" = "infra-charts"
        "url"  = "git@gitlab.login.gov:lg-public/identity-eks-charts.git"
      }
      secretKeyName = "sshPrivateKey"
    }
  }
}

# Deploys our workloads to the cluster
module "gitops_bridge" {
  depends_on = [module.eks_cluster]
  source     = "../modules/gitops_bridge"
  metadata   = module.eks_blueprints_addons.gitops_metadata
  gitops_applications = [
    {
      name           = "infra-charts"
      path           = "applications"
      repoURL        = "git@gitlab.login.gov:lg-public/identity-eks-charts.git"
      targetRevision = "main"
      valueFiles     = ["values.yaml"]
      helmValues = yamlencode({
        awsForFluentBit  = local.fluentbit_config
        fluentd          = local.fluentd_config
        ingressNginx     = local.ingress_nginx_config
        rbacChart        = local.rbac_config
        reviewAppCleanUp = local.review_app_cleanup_config
        rancher          = local.rancher_config
      })
    },
    # Below are all magic add-ons that you can see how to configure here:
    # https://github.com/aws-ia/terraform-aws-eks-blueprints/tree/main/docs/add-ons
    {
      name           = "addons"
      targetRevision = "main"
      path           = "chart"
      repoURL        = "https://github.com/aws-samples/eks-blueprints-add-ons.git"
      helmValues = templatefile("${path.module}/helm-values/addons.yaml.tpl", {
        region          = var.region,
        clusterName     = var.cluster_name,
        repoUrl         = "https://github.com/aws-samples/eks-blueprints-add-ons.git",
        targetRevision  = "main",
        gitops_metadata = module.eks_blueprints_addons.gitops_metadata # All our roles, service account names we setup with eks_addons
      })
      valueFiles = []
    }
  ]
}

output "gitops_metadata" {
  value = module.eks_blueprints_addons.gitops_metadata
}