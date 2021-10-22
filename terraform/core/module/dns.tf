module "common_dns" {
  source = "../../modules/common_dns/"

  domain                        = var.root_domain
  static_cloudfront_name        = var.static_cloudfront_name
  design_cloudfront_name        = var.design_cloudfront_name
  developers_cloudfront_name    = var.developers_cloudfront_name
  acme_partners_cloudfront_name = var.acme_partners_cloudfront_name
  google_site_verification_txt  = var.google_site_verification_txt
  prod_records                  = var.prod_records
  mx_provider                   = var.mx_provider
}

module "dnssec" {
  source = "../../modules/dnssec/"
  providers = {
    aws.usw2 = aws.usw2
    aws.use1 = aws.use1
  }

  dnssec_zone_name = var.root_domain
  dnssec_zone_id   = module.common_dns.primary_zone_id
  alarm_actions    = [module.sns_slack.sns_topic_arn]
}

output "primary_zone_id" {
  description = "ID for the primary Route53 zone."
  value       = module.common_dns.primary_zone_id
}

output "primary_name_servers" {
  description = "Nameservers within the primary Route53 zone."
  value       = [module.common_dns.primary_name_servers]
}

output "primary_domain_mx_servers" {
  description = "List of MXes for domain"
  value       = module.common_dns.primary_domain_mx_servers
}
output "primary_zone_dnssec_ksks" {
  value = module.dnssec.root_zone_dnssec_ksks
}
