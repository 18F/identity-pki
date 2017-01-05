output "aws_login_gov_zone_id" {
  value = "${aws_route53_zone.primary.zone_id}"
}

output "nameservers" {
  value = [
    "${aws_route53_zone.primary.name_servers.0}",
    "${aws_route53_zone.primary.name_servers.1}",
    "${aws_route53_zone.primary.name_servers.2}",
    "${aws_route53_zone.primary.name_servers.3}"
  ]
}

