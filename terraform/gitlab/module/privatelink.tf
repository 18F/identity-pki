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

  tags = {
    Name = var.production ? var.root_domain : "gitlab.${var.env_name}.${var.root_domain}"
  }
}
