module "common_dns" {
  source = "../../modules/common_dns/"

  domain                        = var.root_domain
  static_cloudfront_name        = var.static_cloudfront_name
  design_cloudfront_name        = var.design_cloudfront_name
  developers_cloudfront_name    = var.developers_cloudfront_name
  acme_partners_cloudfront_name = var.acme_partners_cloudfront_name
  google_site_verification_txt  = var.google_site_verification_txt

  mx_provider = var.mx_provider
}

output "primary_zone_id" {
  value = module.common_dns.primary_zone_id
}

output "primary_name_servers" {
  value = [module.common_dns.primary_name_servers]
}

module "sandbox_ses" {
  source = "../../modules/sandbox_ses/"

  domain = var.root_domain

  enabled      = var.sandbox_ses_inbound_enabled
  email_bucket = aws_s3_bucket.s3-email.bucket
}

# TODO: Make this identity-terraform module for SES/DKIM play nicely with identities that exist across regions.

# module "core_ses" {
#   source = "github.com/18F/identity-terraform//ses_dkim_r53?ref=13d442e710c950792388e663237392534af9bc1c"
# 
#   domain                  = var.root_domain
#   zone_id                 = module.common_dns.primary_zone_id
#   ttl_verification_record = "1800"
#   ttl_dkim_records        = "1800"
#   create_token            = true
# }
# 
# module "core_ses_east" {
#   source = "github.com/18F/identity-terraform//ses_dkim_r53?ref=13d442e710c950792388e663237392534af9bc1c"
# 
#   domain                  = var.root_domain
#   zone_id                 = module.common_dns.primary_zone_id
#   ttl_verification_record = "1800"
#   ttl_dkim_records        = "1800"
#   create_token            = false
# }
