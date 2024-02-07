locals {
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  vpc_cidr = "10.0.0.0/16"

  tags = {
    Terraform   = "true"
    Environment = var.cluster_name
  }

  fluentbit_config = yamldecode(templatefile("${path.module}/helm-values/fluent-bit-for-aws.yaml.tpl", {
    region                      = var.region,
    fluentbit_irsa_iam_role_arn = module.fluentbit_irsa.iam_role_arn,
    fluentd_host                = "fluentd.logging.svc.cluster.local"
    fluentd_port                = "24224"
  }))

  fluentd_config = yamldecode(templatefile("${path.module}/helm-values/fluentd.yaml.tpl", {
    region                    = var.region
    fluentd_irsa_iam_role_arn = module.fluentd_irsa.iam_role_arn
  }))

  ingress_nginx_config = yamldecode(templatefile("${path.module}/helm-values/ingress-nginx.yaml.tpl", {
    ingress_nginx_irsa_iam_role_arn = module.ingress_nginx_irsa.iam_role_arn
  }))

  rbac_config               = yamldecode(templatefile("${path.module}/helm-values/rbac-chart.yaml.tpl", {}))
  review_app_cleanup_config = yamldecode(templatefile("${path.module}/helm-values/review-app-cleanup.yaml.tpl", {}))
  rancher_config            = yamldecode(templatefile("${path.module}/helm-values/rancher.yaml.tpl", {}))
}