# set up who has permission to set up a connection to this endpoint service
locals {
  fulladmins   = formatlist("arn:aws:iam::%s:role/FullAdministrator", var.accountids)
  autotfs      = formatlist("arn:aws:iam::%s:role/AutoTerraform", var.accountids)
  terraformers = formatlist("arn:aws:iam::%s:role/Terraform", var.accountids)
  principals   = concat(local.fulladmins, local.autotfs, local.terraformers)
}


# VPC endpoint service so that we can set up VPC endpoints that go to this
resource "aws_vpc_endpoint_service" "gitlab" {
  acceptance_required        = false
  allowed_principals         = local.principals
  network_load_balancer_arns = [aws_lb.gitlab.arn]
  private_dns_name           = var.production ? var.root_domain : "gitlab.${var.env_name}.${var.root_domain}"

  tags = {
    Name = var.production ? var.root_domain : "gitlab.${var.env_name}.${var.root_domain}"
  }
}

# XXX we really should do this, but unfortunately, the verification needs to be in
# the domain level, so for gitlab.login.gov, it needs to live in login.gov, which is
# unable to be edited from the tooling accounts.
#
# resource "aws_route53_record" "gitlab-endpoint-validation" {
#   allow_overwrite = true
#   name            = aws_vpc_endpoint_service.gitlab.private_dns_name_configuration[0].name
#   ttl             = 60
#   records         = [aws_vpc_endpoint_service.gitlab.private_dns_name_configuration[0].value]
#   type            = aws_vpc_endpoint_service.gitlab.private_dns_name_configuration[0].type
#   zone_id         = data.aws_route53_zone.gitlab.zone_id
# }
