provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["555546682965"] # require identity-prod
  profile             = "login.gov"
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
          "name"    = "_acme-challenge.",
          "records" = ["g_ybuPyxTGP-JeDhOA-AyjIlJEwsZU5fd0dr7zvpFsg"],
          "ttl"     = "120",
        },
        {
          "name"    = "_acme-challenge.www.",
          "records" = ["L1XfURLRizB_sP022sBOoQGaulRl34R9B3xEZxTTFfs"],
          "ttl"     = "120",
        },
        {
          "name"    = "_acme-challenge.partners.",
          "records" = ["l0DvBtdqJcAcfwmje4YpBglqymSl5xVFseBiMiZf3hE"],
          "ttl"     = "120",
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
          "name"    = "_acme-challenge.demo.",
          "records" = ["_acme-challenge.demo.login.gov.external-domains-production.cloud.gov."],
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
          "name"    = "demo.",
          "records" = ["demo.login.gov.external-domains-production.cloud.gov."],
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
          "name"    = "hs1._domainkey.",
          "records" = ["login-gov.hs01a.dkim.hubspotemail.net."],
          "ttl"     = "900",
        },
        {
          "name"    = "hs2._domainkey.",
          "records" = ["login-gov.hs01b.dkim.hubspotemail.net."],
          "ttl"     = "900",
        },
      ]
    },
    {
      type = "A",
      record_set = [
        {
          "name"    = "out-49.mail.",
          "records" = ["54.240.62.49"],
          "ttl"     = "86400",
        },
        {
          "name"    = "out-50.mail.",
          "records" = ["54.240.62.50"],
          "ttl"     = "86400",
        },
        {
          "name"    = "test.dev.",
          "records" = ["54.202.194.128"],
          "ttl"     = "300",
        },
      ]
    }
  ]

  root_domain                   = "login.gov"
  static_cloudfront_name        = "db1mat7gaslfp.cloudfront.net"
  design_cloudfront_name        = "d28khhcfeuwd3y.cloudfront.net"
  developers_cloudfront_name    = "d26qb7on2m22yd.cloudfront.net"
  acme_partners_cloudfront_name = "dbahbj6k864a6.cloudfront.net"
  google_site_verification_txt  = "x8WM0Sy9Q4EmkHypuULXjTibNOJmPEoOxDGUmBppws8"
  mx_provider                   = "google-g-suite"
  lambda_audit_github_debug     = 0

  bucket_list_uw2 = [
    "555546682965-awsmacietrail-dataevent",
    "aws-athena-query-results-555546682965-us-west-2",
    "cf-templates-iccjd8v5q7bo-us-west-2",
    "config-bucket-555546682965",
    "configruleslogingov",
    "importfireeyethreatfeedi-gdthreatfeedoutputbucket-7kom7besttlo",
    "importfireeyethreatfeedt-gdthreatfeedoutputbucket-1j2fdxqvqlcby",
    "login-dot-gov-analytics-terraform-state",
    "login-dot-gov-security-logs",
    "login-gov-analytics-dependencies",
    "login-gov-analytics-migration",
    "login-gov-backup",
    "login-gov-dev-analytics",
    "login-gov-dm-analytics-logs",
    "login-gov-fraud-models",
    "login-gov-geolocation-db-555546682965",
    "login-gov-global-trail",
    "login-gov-int-analytics",
    "login-gov-int-analytics-hot",
    "login-gov-int-analytics-logs",
    "login-gov-int-analytics-parquet",
    "login-gov-int-logs",
    "login-gov-int-logs-bak",
    "login-gov-prod-analytics-hot",
    "login-gov-prod-analytics-parquet",
    "login-gov-prod-redshift-secrets",
    "login-gov-qa-analytics",
    "login-gov-qa-analytics-logs",
    "login-gov-redshift-int-secrets",
    "login-gov-s3bucket-access-logging",
    "login-gov-staging-redshift-secrets",
    "login-gov.app-secrets.555546682965-us-west-2",
    "login-gov.email.555546682965-us-west-2",
    "login-gov.shared-secrets",
    "login-gov.waf-logs.555546682965-us-west-2",
    "tf-fraud-bucket-depployments",
    "tf-redshift-bucket-deployments",
    "tf-redshift-bucket-deployments-hot",
    "tf-redshift-bucket-dev-secrets",
    "tf-redshift-bucket-dm-deployments",
    "tf-redshift-bucket-prod-deployments",
    "tf-redshift-bucket-staging-deployments",
  ]

  bucket_list_ue1 = [
    "login-dot-gov-bad-perms-test",
    "login_dot_gov_tf_state",
  ]
}
