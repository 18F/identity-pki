output "primary_zone_id" {
  description = "ID for the primary Route53 zone."
  value       = aws_route53_zone.primary.zone_id
}

output "primary_domain" {
  description = "DNS domain to use as the root domain, e.g. 'login.gov.'"
  value       = var.domain
}

output "primary_name_servers" {
  description = "Nameservers within the primary Route53 zone."
  value = [
    for num in range(4) : element(aws_route53_zone.primary.name_servers, num)
  ]
}

output "primary_domain_mx_servers" {
  description = "List of MXes for domain"
  value = [for v in split(",", var.mx_record_map[var.mx_provider]) :
    regex("^[0-9 ]*([^\\s]+?)\\.?$", v)[0]
  ]
}
