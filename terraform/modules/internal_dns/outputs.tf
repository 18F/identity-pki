output "internal_zone_id" {
  value = aws_route53_zone.internal.zone_id
}

output "internal_ns" {
  description = "Nameservers within the Route53 private hosted zone."
  value = [
    for x in range(4) : element(aws_route53_zone.internal.name_servers, x)
  ]
}