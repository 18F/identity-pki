provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["555546682965"] # require identity-prod
  profile             = "login.gov"
  version             = "~> 2.37.0"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  lambda_audit_github_enabled   = 0
  lambda_audit_aws_enabled      = 0
  state_lock_table              = "terraform_locks"
  slack_events_sns_hook_arn     = "arn:aws:sns:us-west-2:555546682965:slack-identity-events"

  prod_records = [
    {
      type = "TXT",
      record_set = [
      {
        "name"    = "identitysandbox.gov._report._dmarc",
        "records" = ["v=DMARC1"],
        "ttl"     = "3600",
      },
      {
        "name"    = "connect.gov._report._dmarc",
        "records" = ["v=DMARC1"],
        "ttl"     = "3600",
      },
      {
        "name"    = "google._domainkey",
        "records" = ["v=DKIM1; k=rsa; p=v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAkcuOOdgaWfHIKM1ILlzPOHBPJKLxU9+1+ufIprNdjrD+QQ6/uJtc/tP5s1MUwYU/fld2Y1QwXC5JHdE6JXP31XwCtvbfIwn/Dr/EaRB3PomOp0SNbTtFMmvuxPF87HidvzDH3cWXcmyjMx6XU1i9O3nBs66Z+8i4gfh/PZdjJs6wcNp9urJjCo23KYzbiNAn\"\"7FJjbD4g3NucMvkBXHIsOMLvb7WzIekpxL2bjz6XlDfK1t4VTLv4IqIlLMfhYGwwaWPhgyra7qezYkp6a2XSoLWxPWRbfb1bNmVUJ7vBeB6NdFnr9n/7TqbhDVEo9/XyO1MIsuNTTZuhurlZqoXx0QIDAQAB"],
        "ttl"     = "900",
      },
      {
        "name"    = "_acme-challenge",
        "records" = ["g_ybuPyxTGP-JeDhOA-AyjIlJEwsZU5fd0dr7zvpFsg"],
        "ttl"     = "120",
      },
      {
        "name"    = "_acme-challenge.www",
        "records" = ["L1XfURLRizB_sP022sBOoQGaulRl34R9B3xEZxTTFfs"],
        "ttl"     = "120",
      },
      {
        "name"    = "_acme-challenge.partners",
        "records" = ["l0DvBtdqJcAcfwmje4YpBglqymSl5xVFseBiMiZf3hE"],
        "ttl"     = "120",
      },
      {
        "name"    = "smtpapi._domainkey",
        "records" = ["L1XfURLRizB_sP022sBOoQGaulRl34R9B3xEZxTTFk=rsa; t=s; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDPtW5iwpXVPiH5FzJ7Nrl8USzuY9zqqzjE0D1r04xDN6qwziDnmgcFNNfMewVKN2D1O+2J9N14hRprzByFwfQW76yojh54Xu3uSbQ3JP0A7k8o8GutRF8zbFUA8n0ZH2y0cIEjMliXY4W4LwPA7m4q0ObmvSjhd6\"\"3O9d8z1XkUBwIDAQAB"],
        "ttl"     = "900",
      },
    ]
    },
    {
      type = "CNAME",
      record_set = [
      {
        "name"    = "hs1._domainkey",
        "records" = ["login-gov.hs01a.dkim.hubspotemail.net."],
        "ttl"     = "900",
      },
      {
        "name"    = "hs2._domainkey",
        "records" = ["login-gov.hs01b.dkim.hubspotemail.net."],
        "ttl"     = "900",
      },
    ]
    },
    {
      type = "A",
      record_set = [
      {
        "name"    = "out-49.mail",
        "records" = ["54.240.62.49"],
        "ttl"     = "86400",
      },
      {
        "name"    = "out-50.mail",
        "records" = ["54.240.62.50"],
        "ttl"     = "86400",
      },
      {
        "name"    = "test.dev",
        "records" = ["54.202.194.128"],
        "ttl"     = "300",
      },
      ]
    }
  }

  root_domain                   = "login.gov"
  static_cloudfront_name        = "db1mat7gaslfp.cloudfront.net"
  design_cloudfront_name        = "d28khhcfeuwd3y.cloudfront.net"
  developers_cloudfront_name    = "d26qb7on2m22yd.cloudfront.net"
  acme_partners_cloudfront_name = "dbahbj6k864a6.cloudfront.net"
  google_site_verification_txt  = "x8WM0Sy9Q4EmkHypuULXjTibNOJmPEoOxDGUmBppws8"
  mx_provider                   = "google-g-suite"
  lambda_audit_github_debug     = 0
  cloudtrail_logging_bucket     = "login-gov-s3bucket-access-logging"
  cloudtrail_event_selectors    = [
    {
      include_management_events = false
      read_write_type           = "WriteOnly"
      
      data_resources = [
        {
          type = "AWS::S3::Object"
          values = [
            "arn:aws:s3:::config-bucket-555546682965/",
            "arn:aws:s3:::configruleslogingov/",
            "arn:aws:s3:::login-dot-gov-analytics-terraform-state/",
            "arn:aws:s3:::login-dot-gov-security-logs/",
            "arn:aws:s3:::login-gov--redshift-secrets/",
            "arn:aws:s3:::login-gov-analytics-dependencies/",
            "arn:aws:s3:::login-gov-backup/",
            "arn:aws:s3:::login-gov-cloudtrail-555546682965/",
            "arn:aws:s3:::login-gov-dev-analytics/",
            "arn:aws:s3:::login-gov-dev-analytics-logs/",
            "arn:aws:s3:::login-gov-dev-logs/",
            "arn:aws:s3:::login-gov-dev-redshift-secrets/",
            "arn:aws:s3:::login-gov-dm-analytics/",
            "arn:aws:s3:::login-gov-dm-analytics-logs/",
            "arn:aws:s3:::login-gov-dm-logs/",
            "arn:aws:s3:::login-gov-dm-redshift-secrets/",
            "arn:aws:s3:::login-gov-elasticsearch-dm.555546682965-us-west-2/",
            "arn:aws:s3:::login-gov-elasticsearch-prod.555546682965-us-west-2/",
            "arn:aws:s3:::login-gov-elasticsearch-staging.555546682965-us-west-2/",
            "arn:aws:s3:::login-gov-fraud-models/",
            "arn:aws:s3:::login-gov-global-trail/",
            "arn:aws:s3:::login-gov-int-analytics/",
            "arn:aws:s3:::login-gov-int-analytics-hot/",
            "arn:aws:s3:::login-gov-int-analytics-logs/",
            "arn:aws:s3:::login-gov-int-analytics-parquet/",
            "arn:aws:s3:::login-gov-int-logs/",
            "arn:aws:s3:::login-gov-int-logs-bak/",
            "arn:aws:s3:::login-gov-int-redshift-secrets/",
            "arn:aws:s3:::login-gov-internal-certs-test-us-west-2-555546682965/",
            "arn:aws:s3:::login-gov-internal-certs-test-us-west-2-555546682965-logs/",
            "arn:aws:s3:::login-gov-prod-analytics-hot/",
            "arn:aws:s3:::login-gov-prod-analytics-logs/",
            "arn:aws:s3:::login-gov-prod-analytics-parquet/",
            "arn:aws:s3:::login-gov-proxylogs-dm.555546682965-us-west-2/",
            "arn:aws:s3:::login-gov-proxylogs-int.555546682965-us-west-2/",
            "arn:aws:s3:::login-gov-proxylogs-prod.555546682965-us-west-2/",
            "arn:aws:s3:::login-gov-proxylogs-staging.555546682965-us-west-2/",
            "arn:aws:s3:::login-gov-pt-analytics/",
            "arn:aws:s3:::login-gov-pt-analytics-hot/",
            "arn:aws:s3:::login-gov-pt-analytics-logs/",
            "arn:aws:s3:::login-gov-pt-analytics-parquet/",
            "arn:aws:s3:::login-gov-pt-redshift-secrets/",
            "arn:aws:s3:::login-gov-qa-analytics/",
            "arn:aws:s3:::login-gov-qa-analytics-logs/",
            "arn:aws:s3:::login-gov-qa-chefstuff/",
            "arn:aws:s3:::login-gov-qa-logs/",
            "arn:aws:s3:::login-gov-qa-redshift-secrets/",
            "arn:aws:s3:::login-gov-redshift-int-secrets/",
            "arn:aws:s3:::login-gov-secrets-test/",
            "arn:aws:s3:::login-gov-shared-data-555546682965/",
            "arn:aws:s3:::login-gov-staging-analytics/",
            "arn:aws:s3:::login-gov-staging-analytics-logs/",
            "arn:aws:s3:::login-gov-staging-logs/",
            "arn:aws:s3:::login-gov-staging-redshift-secrets/",
            "arn:aws:s3:::login-gov-testing/",
            "arn:aws:s3:::login-gov-tspencer-logs/",
            "arn:aws:s3:::login-gov-tspencer-secrets/",
            "arn:aws:s3:::login-gov.elb-logs.555546682965-us-west-2/",
            "arn:aws:s3:::login-gov.email.555546682965-us-west-2/",
            "arn:aws:s3:::login-gov.s3-logs.555546682965-us-west-2/",
            "arn:aws:s3:::tf-fraud-bucket-depployments/",
            "arn:aws:s3:::tf-redshift-bucket-deployments/",
            "arn:aws:s3:::tf-redshift-bucket-deployments-hot/",
            "arn:aws:s3:::tf-redshift-bucket-dev-deployments/",
            "arn:aws:s3:::tf-redshift-bucket-dev-secrets/",
            "arn:aws:s3:::tf-redshift-bucket-dm-deployments/",
            "arn:aws:s3:::tf-redshift-bucket-int-deployments/",
            "arn:aws:s3:::tf-redshift-bucket-prod-deployments/",
            "arn:aws:s3:::tf-redshift-bucket-qa-deployments/",
            "arn:aws:s3:::tf-redshift-bucket-staging-deployments/",
          ]
        },
      ]
    },
    {
      include_management_events = true
      read_write_type           = "All"
      
      data_resources = [
        {
          type = "AWS::S3::Object"
          values = [
            "arn:aws:s3:::555546682965-awsmacietrail-dataevent/",
            "arn:aws:s3:::aws-athena-query-results-555546682965-us-west-2/",
            "arn:aws:s3:::aws-glue-scripts-555546682965-us-west-2/",
            "arn:aws:s3:::aws-glue-temporary-555546682965-us-west-2/",
            "arn:aws:s3:::cf-templates-iccjd8v5q7bo-us-west-2/",
            "arn:aws:s3:::lgoin-gov.super-secrets/",
            "arn:aws:s3:::login-gov.shared-secrets/",
            "arn:aws:s3:::login-gov.super-secrets/",
          ]
        },
      ]
    },    
  ]
}
