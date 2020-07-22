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

module "sandbox_ses" {
  source = "../../modules/sandbox_ses/"

  domain       = var.root_domain
  enabled      = var.sandbox_ses_inbound_enabled
  email_bucket = element(module.s3_shared.buckets, index(module.s3_shared.buckets, "email"))
}

output "primary_zone_id" {
  description = "ID for the primary Route53 zone."
  value       = module.common_dns.primary_zone_id
}

output "primary_name_servers" {
  description = "Nameservers within the primary Route53 zone."
  value       = [module.common_dns.primary_name_servers]
}


