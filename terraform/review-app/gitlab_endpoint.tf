resource "aws_route53_zone" "internal" {
  comment = "${var.cluster_name}-internal-zone"
  name    = "login.gov.internal"
  vpc {
    vpc_id = module.vpc.vpc_id
  }
}

module "gitlab" {
  source                  = "../modules/gitlab"
  gitlab_servicename      = "com.amazonaws.vpce.us-west-2.vpce-svc-0270024908d73003b"
  endpoint_subnet_ids     = module.vpc.private_subnets
  vpc_id                  = module.vpc.vpc_id
  env_name                = var.cluster_name
  allowed_security_groups = [module.eks_cluster.node_security_group_id]
  dns_name                = "gitlab.login.gov"
  route53_zone_id         = aws_route53_zone.internal.zone_id
}