module "usps_updates" {
  count  = var.enable_usps_status_updates ? 1 : 0
  source = "../modules/usps_status_update_via_email"

  env_name    = var.env_name
  root_domain = var.root_domain
  route53_id  = var.route53_id
}