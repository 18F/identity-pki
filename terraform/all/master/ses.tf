### SES identity for master account###
module "master_ses" {
  source = "github.com/18F/identity-terraform//ses_dkim_r53?ref=main"

  domain           = "humans.login.gov"
  zone_id          = "Z2DA4DCW3GKJVW"
  ttl_dkim_records = "1800"
}