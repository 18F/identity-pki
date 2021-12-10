provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["917793222841"] # require login-alpha
  profile             = "login-alpha"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  state_lock_table = "terraform_locks"
  slack_sns_name   = "slack-sandbox-events"
  root_domain      = "alpha.identitysandbox.gov"

  # To safely rotate see https://github.com/18F/identity-devops/wiki/Runbook:-DNS#ksk-rotation
  dnssec_ksks = {
    # "20211005" = "old",
    "20211006" = "active"
  }

  # TODO - Remove the need for these.  Set to the same as prod
  # for now to ensure we control the target
  static_cloudfront_name        = "db1mat7gaslfp.cloudfront.net"
  design_cloudfront_name        = "d28khhcfeuwd3y.cloudfront.net"
  developers_cloudfront_name    = "d26qb7on2m22yd.cloudfront.net"
  acme_partners_cloudfront_name = "dbahbj6k864a6.cloudfront.net"
  prod_records = [
    {
      type = "NS",
      record_set = [
        {
          "name" = "gitlab.",
          "records" = [
            "ns-10.awsdns-01.com.",
            "ns-751.awsdns-29.net.",
            "ns-1788.awsdns-31.co.uk.",
            "ns-1074.awsdns-06.org.",
          ],
          "ttl" = "900",
        },
      ]
    }
  ]

  mx_provider                 = "amazon-ses-inbound.us-west-2"
  sandbox_ses_inbound_enabled = 1
  sandbox_ses_email_users     = ["smoketest-dev", "smoketest-int", "smoketest-staging", "smoketest-prod"]
  mta_sts_report_mailboxes    = ["tls.reports@gsa.gov", "tls-reports@login.gov"]
  mta_sts_mode                = "enforce"

  slack_events_sns_hook_arn = "arn:aws:sns:us-west-2:917793222841:slack-otherevents"
}

module "gd-events-to-logs" {
  source = "../../modules/gd_findings_to_events"
}

module "gd-log-sub-filter-sandbox" {
  depends_on                          = [module.gd-events-to-logs]
  source                              = "../../modules/log_ship_to_soc"
  region                              = "us-west-2"
  cloudwatch_subscription_filter_name = "gd-log-ship-to-soc"
  cloudwatch_log_group_name = {
    "GuardDutyFindings/LogGroup" = ""
  }
  env_name            = "sandbox-gd"
  soc_destination_arn = "arn:aws:logs:us-west-2:752281881774:destination:elp-guardduty-lg"

}

output "primary_zone_dnssec_ksks" {
  value = module.main.primary_zone_dnssec_ksks
}

output "primary_zone_active_ds_value" {
  value = module.main.primary_zone_active_ds_value
}

