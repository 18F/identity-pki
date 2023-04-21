resource "aws_acm_certificate" "wildcard" {
  domain_name       = "*.${var.dnszone}"
  validation_method = "DNS"

  tags = {
    Name      = "${var.cluster_name}-wildcard"
    Terraform = "true"
  }
}