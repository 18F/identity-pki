data "aws_s3_bucket" "secrets" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.id}-${var.region}"
}

data "aws_vpc_endpoint_service" "email-smtp" {
  service      = "email-smtp"
  service_type = "Interface"
}

data "aws_network_interface" "lb" {
  count = length(local.private_subnet_ids)

  filter {
    name   = "description"
    values = ["ELB ${aws_lb.gitlab.arn_suffix}"]
  }
  filter {
    name   = "subnet-id"
    values = ["${element(local.private_subnet_ids, count.index)}"]
  }

  depends_on = [
    aws_lb.gitlab
  ]
}
