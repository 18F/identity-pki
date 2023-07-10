# Set up an internal dns zone that we can use for service discovery

resource "aws_route53_zone" "internal-reverse" {
  comment = "${var.name}-zone-${var.env_name}"
  name    = "16.172.in-addr.arpa"
  vpc {
    vpc_id = aws_vpc.default.id
  }
}

module "internal_dns_uw2" {
  source = "../modules/internal_dns"

  env_name = var.env_name
  name     = var.name
  vpc_id   = aws_vpc.default.id

}

##### moved blocks, remove once state moves are complete

moved {
  from = aws_route53_zone.internal
  to   = module.internal_dns_uw2.aws_route53_zone.internal
}

moved {
  from = aws_route53_record.aws_route53_record
  to   = module.internal_dns_uw2.aws_route53_record.internal-ns
}

output "test_outputs" {
  value = module.internal_dns_uw2
}
