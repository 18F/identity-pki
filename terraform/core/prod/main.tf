provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["555546682965"] # require identity-prod
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  lambda_audit_github_enabled = 0
  lambda_audit_aws_enabled    = 0
  state_lock_table            = "terraform_locks"
  slack_sns_name              = "slack-prod-events"

  prod_records = [
    {
      type = "TXT",
      record_set = [
        {
          "name"    = "identitysandbox.gov._report._dmarc.",
          "records" = ["v=DMARC1"],
          "ttl"     = "3600",
        },
        {
          "name"    = "connect.gov._report._dmarc.",
          "records" = ["v=DMARC1"],
          "ttl"     = "3600",
        },
        {
          "name"    = "google._domainkey.",
          "records" = ["v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAkcuOOdgaWfHIKM1ILlzPOHBPJKLxU9+1+ufIprNdjrD+QQ6/uJtc/tP5s1MUwYU/fld2Y1QwXC5JHdE6JXP31XwCtvbfIwn/Dr/EaRB3PomOp0SNbTtFMmvuxPF87HidvzDH3cWXcmyjMx6XU1i9O3nBs66Z+8i4gfh/PZdjJs6wcNp9urJjCo23KYzbiNAn\" \"7FJjbD4g3NucMvkBXHIsOMLvb7WzIekpxL2bjz6XlDfK1t4VTLv4IqIlLMfhYGwwaWPhgyra7qezYkp6a2XSoLWxPWRbfb1bNmVUJ7vBeB6NdFnr9n/7TqbhDVEo9/XyO1MIsuNTTZuhurlZqoXx0QIDAQAB"],
          "ttl"     = "3600",
        },
        {
          "name"    = "smtpapi._domainkey.",
          "records" = ["L1XfURLRizB_sP022sBOoQGaulRl34R9B3xEZxTTFk=rsa; t=s; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDPtW5iwpXVPiH5FzJ7Nrl8USzuY9zqqzjE0D1r04xDN6qwziDnmgcFNNfMewVKN2D1O+2J9N14hRprzByFwfQW76yojh54Xu3uSbQ3JP0A7k8o8GutRF8zbFUA8n0ZH2y0cIEjMliXY4W4LwPA7m4q0ObmvSjhd6\"\"3O9d8z1XkUBwIDAQAB"],
          "ttl"     = "900",
        },
      ]
    },
    {
      type = "CNAME",
      record_set = [
        {
          "name"    = "_acme-challenge.",
          "records" = ["_acme-challenge.login.gov.external-domains-production.cloud.gov."],
          "ttl"     = "900",
        },
        {
          "name"    = "_acme-challenge.data.",
          "records" = ["_acme-challenge.data.login.gov.external-domains-production.cloud.gov."],
          "ttl"     = "900",
        },
        {
          "name"    = "_acme-challenge.developer.",
          "records" = ["_acme-challenge.developer.login.gov.external-domains-production.cloud.gov."],
          "ttl"     = "900",
        },
        {
          "name"    = "_acme-challenge.handbook.",
          "records" = ["_acme-challenge.handbook.login.gov.external-domains-production.cloud.gov."],
          "ttl"     = "900",
        },
        {
          "name"    = "_acme-challenge.partners.",
          "records" = ["_acme-challenge.partners.login.gov.external-domains-production.cloud.gov."],
          "ttl"     = "900",
        },
        {
          "name"    = "_acme-challenge.www.",
          "records" = ["_acme-challenge.www.login.gov.external-domains-production.cloud.gov."],
          "ttl"     = "900",
        },
        {
          "name"    = "data.",
          "records" = ["data.login.gov.external-domains-production.cloud.gov."],
          "ttl"     = "900",
        },
        {
          "name"    = "developer.",
          "records" = ["developer.login.gov.external-domains-production.cloud.gov."],
          "ttl"     = "900",
        },
        {
          "name"    = "handbook.",
          "records" = ["handbook.login.gov.external-domains-production.cloud.gov."],
          "ttl"     = "900",
        },
        {
          "name"    = "partners.",
          "records" = ["partners.login.gov.external-domains-production.cloud.gov."],
          "ttl"     = "900",
        },
        {
          "name"    = "status.",
          "records" = ["8xj4141vpqw4.stspg-customer.com."],
          "ttl"     = "900",
        },
        {
          "name"    = "hs1._domainkey.",
          "records" = ["login-gov.hs01a.dkim.hubspotemail.net."],
          "ttl"     = "900",
        },
        {
          "name"    = "hs2._domainkey.",
          "records" = ["login-gov.hs01b.dkim.hubspotemail.net."],
          "ttl"     = "900",
        },
        {
          "name"    = "zendesk.",
          "records" = ["logingov.zendesk.com."],
          "ttl"     = "900",
        }
      ]
    },
    {
      type = "A",
      record_set = [
        {
          # Outbound SES SMTP - a62-49.smtp-out.us-west-2.amazonses.com.
          "name"    = "out-49.mail.",
          "records" = ["54.240.62.49"],
          "ttl"     = "86400",
        },
        {
          # Outbound SES SMTP - a62-50.smtp-out.us-west-2.amazonses.com.
          "name"    = "out-50.mail.",
          "records" = ["54.240.62.50"],
          "ttl"     = "86400",
        },
      ]
    }
  ]

  root_domain = "login.gov"

  # To safely rotate see https://github.com/18F/identity-devops/wiki/Runbook:-DNS#ksk-rotation
  dnssec_ksks = {
    # 20211005" = "old",
    "20211006" = "active"
  }

  static_cloudfront_name       = "db1mat7gaslfp.cloudfront.net"
  design_cloudfront_name       = "d28khhcfeuwd3y.cloudfront.net"
  developers_cloudfront_name   = "d26qb7on2m22yd.cloudfront.net"
  google_site_verification_txt = "XpAHhjdX8tbSoncavYqzKuquO0ystD12VzLmXR10CK0" # associated with zachary.margolis@gsa.gov
  mx_provider                  = "google-g-suite"
  mta_sts_report_mailboxes     = ["tls.reports@gsa.gov", "tls-reports@login.gov"]
  mta_sts_mode                 = "enforce"
  lambda_audit_github_debug    = 0

  slack_events_sns_hook_arn = "arn:aws:sns:us-west-2:555546682965:slack-events"
}

module "gd-events-to-logs-prod" {
  source = "../../modules/gd_findings_to_events"
}

module "gd-log-sub-filter-prod" {
  depends_on                          = [module.gd-events-to-logs-prod]
  source                              = "../../modules/log_ship_to_soc"
  region                              = "us-west-2"
  cloudwatch_subscription_filter_name = "gd-log-ship-to-soc"
  cloudwatch_log_group_name = {
    "/aws/events/gdfindings" = ""
  }
  env_name            = "prod-gd"
  soc_destination_arn = "arn:aws:logs:us-west-2:752281881774:destination:elp-guardduty-lg"

}

module "macie-bucket-scans-prod" {
  source = "../../modules/macie_v2"
  macie_scan_buckets = [
    "login-gov-pivcac-dm.555546682965-us-west-2",
    "login-gov-pivcac-prod.555546682965-us-west-2",
    "login-gov-pivcac-staging.555546682965-us-west-2",
    "login-gov-pivcac-public-cert-dm.555546682965-us-west-2",
    "login-gov-pivcac-public-cert-prod.555546682965-us-west-2",
    "login-gov-pivcac-public-cert-staging.555546682965-us-west-2",
    "login-gov-log-cache-dm.555546682965-us-west-2",
    "login-gov-log-cache-prod.555546682965-us-west-2",
    "login-gov-log-cache-staging.555546682965-us-west-2",
    "login-gov.app-secrets.555546682965-us-west-2",
    "login-gov.secrets.555546682965-us-west-2",
  ]
}

output "primary_zone_dnssec_ksks" {
  value = module.main.primary_zone_dnssec_ksks
}

output "primary_zone_active_ds_value" {
  value = module.main.primary_zone_active_ds_value
}
