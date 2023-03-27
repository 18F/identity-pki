data "aws_s3_bucket" "secrets" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.id}-${var.region}"
}

data "aws_vpc_endpoint_service" "email-smtp" {
  service      = "email-smtp"
  service_type = "Interface"
}

data "aws_network_interface" "lb" {
  for_each = aws_lb.gitlab.subnets

  filter {
    name   = "description"
    values = ["ELB ${aws_lb.gitlab.arn_suffix}"]
  }

  filter {
    name   = "subnet-id"
    values = [each.value]
  }

  depends_on = [
    aws_lb.gitlab
  ]
}

data "aws_availability_zones" "available" {}

data "aws_vpc_endpoint_service" "smtp" {
  service = "email-smtp"
}

data "aws_subnets" "smtp_subnets" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc_ipv4_cidr_block_association.secondary_cidr.vpc_id]
  }

  filter {
    name   = "subnet-id"
    values = [for zone in local.network_zones : aws_subnet.endpoints[zone].id]
  }

  filter {
    name   = "availability-zone"
    values = data.aws_vpc_endpoint_service.smtp.availability_zones
  }
}

data "aws_ami" "base" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["login.gov base role hardened image Ubuntu*"]
  }

  filter {
    name   = "tag:Role"
    values = ["base"]
  }

  filter {
    name   = "tag:Branch_Name"
    values = ["main"]
  }

  filter {
    name   = "tag:OS_Version"
    values = ["Ubuntu 18.04"]
  }
}


