
data "aws_availability_zones" "available" {}

resource "aws_vpc_endpoint" "gitlab" {
  service_name        = var.gitlab_servicename
  subnet_ids          = var.endpoint_subnet_ids
  vpc_id              = var.vpc_id
  security_group_ids  = [aws_security_group.gitlab.id]
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  tags = {
    Name = "${var.name}-gitlab-${var.env_name}"
  }
}

resource "aws_security_group" "gitlab" {
  name        = "${var.env_name}-gitlab"
  description = "security group attached to gitlab privatelink endpoint for ${var.env_name}"
  vpc_id      = var.vpc_id

  # this allows the gitlab runners to register with gitlab
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = var.allowed_security_groups
  }

  # this allows everybody to git pull
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = var.allowed_security_groups
  }

  tags = {
    Name = "${var.env_name}-gitlab"
  }
}

resource "aws_route53_record" "gitlab" {
  zone_id = var.route53_zone_id
  name    = var.dns_name
  type    = "CNAME"
  ttl     = "300"
  records = [aws_vpc_endpoint.gitlab.dns_entry[0]["dns_name"]]
}
