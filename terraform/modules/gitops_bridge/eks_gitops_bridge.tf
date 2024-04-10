################################################################################
# GitOps Bridge: Bootstrap
# https://github.com/gitops-bridge-dev/gitops-bridge-argocd-bootstrap-terraform/blob/main/main.tf
################################################################################
module "gitops_bridge_bootstrap" {
  source = "github.com/gitops-bridge-dev/gitops-bridge-argocd-bootstrap-terraform?ref=v2.0.0"

  argocd = {
    create_namespace = true
    chart_version    = "5.51.6"
    values = [templatefile("${path.module}/templates/argocd-values.yaml.tpl", {
    })]
  }

  cluster = {
    name        = var.cluster_name
    metadata    = var.metadata
    environment = var.cluster_name
  }

  # Iterate over gitops_applications and create ArgoCD applications
  # and the cluster config
  apps = merge(
    { for app in var.gitops_applications : app.name => templatefile("${path.module}/templates/application.yaml.tpl", app) },
    { cluster-control = templatefile("${path.module}/templates/cluster-control.yaml.tpl", { cluster_name = "${var.cluster_name}" }) }
  )
}