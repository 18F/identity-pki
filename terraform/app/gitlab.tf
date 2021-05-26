# This enables the gitlab privatelink endpoint in the VPC so that
# we can get to gitlab from the environments that have
# `gitlab_enabled` turned on.
module "gitlab" {
  count      = var.gitlab_enabled ? 1 : 0
  depends_on = [aws_internet_gateway.default]
  source     = "../modules/gitlab"

  gitlab_servicename       = var.gitlab_servicename
  gitlab_subnet_cidr_block = var.gitlab_subnet_cidr_block
  vpc_id                   = aws_vpc.default.id
  name                     = var.name
  env_name                 = var.env_name
  allowed_security_groups  = [aws_security_group.base.id]
  route53_zone_id          = aws_route53_zone.internal.zone_id
  dns_name                 = var.gitlab_hostname
}
