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
  source = "github.com/18F/identity-terraform//dnssec?ref=2804b4b09312e23eb6f2e680f24ed4f57e6aeda0"
  #source = "../../../../identity-terraform/dnssec"

  dnssec_ksks_action_req_alarm_desc = "${local.dnssec_runbook_prefix}_ksks_action_req"
  dnssec_ksk_age_alarm_desc         = "${local.dnssec_runbook_prefix}_ksk_age"
  dnssec_errors_alarm_desc          = "${local.dnssec_runbook_prefix}_errors"
  dnssec_zone_name                  = var.root_domain
  dnssec_zone_id                    = module.common_dns.primary_zone_id
  alarm_actions                     = [module.sns_slack.sns_topic_arn]
  dnssec_ksks                       = var.dnssec_ksks # Require setting explicity for top level zones
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

output "primary_zone_active_ds_value" {
  value = module.dnssec.active_ds_value
}

