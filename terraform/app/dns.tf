# Set up an internal dns zone that we can use for service discovery

resource "aws_route53_zone" "internal-reverse" {
  comment = "${var.name}-zone-${var.env_name}"
  name    = "16.172.in-addr.arpa"
  vpc {
    vpc_id = module.network_usw2.vpc_id
  }
}

module "internal_dns_uw2" {
  source = "../modules/internal_dns"

  env_name = var.env_name
  name     = var.name
  vpc_id   = module.network_usw2.vpc_id

}

##### moved blocks, remove once state moves are complete

moved {
  from = aws_route53_zone.internal
  to   = module.internal_dns_uw2.aws_route53_zone.internal
}

moved {
  from = aws_route53_record.internal-ns
  to   = module.internal_dns_uw2.aws_route53_record.internal_ns
}