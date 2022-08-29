provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["894947205914"] # require identity-sandbox
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
  root_domain      = "identitysandbox.gov"

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

  bucket_list_uw2 = [
    "894947205914-awsmacietrail-dataevent",
    "894947205914-tf",
    "aws-athena-query-results-894947205914-us-west-2",
    "cf-templates-1am4wkz4zazy5-us-west-2",
    "codepipeline-us-west-2-761616215033",
    "codesync-identitybaseimage-keybucket-ln1a6mvvs9ow",
    "codesync-identitybaseimage-lambdazipsbucket-vhwlv2eotkhq",
    "codesync-identitybaseimage-outputbucket-rlnx3kivn8t8",
    "configrulesdevlogingov",
    "cw-syn-results-894947205914-us-west-2",
    "dev-s3-access-logs",
    "gsa-to3-18f-3",
    "guarddutyfireeyedemo1-gdthreatfeedoutputbucket-1lfkj1b9tcvkk",
    "guarddutythreatfeed-gdthreatfeedoutputbucket-1byh8perllwqx",
    "guarddutythreatfeed-gdthreatfeedoutputbucket-24a4k1ga8og2",
    "guarddutythreatfeed-gdthreatfeedoutputbucket-74vz0nyrf8dx",
    "ingest-threat-feed-into-gdthreatfeedoutputbucket-172rf8w89zof0",
    "ingestthreatfeedsintogua-gdthreatfeedoutputbucket-11crg9yz9gmez",
    "lg-af-test-bucket",
    "login-dot-gov-secops.894947205914-us-west-2",
    "login-dot-gov-tf-state-894947205914",
    "login-gov-auth",
    "login-gov-backup-tmp-secrets",
    "login-gov-cloudformation",
    "login-gov-doc",
    "login-gov-jjg-analytics-secrets",
    "login-gov-kinesis-failed-events",
    "login-gov-s3-object-logging-dev",
    "login-gov-test-coverage",
    "login-gov.scripts.lambda",
    "login-test-backup",
    "overbridgeconfigbucket-us-west-2-894947205914",
    "pauldoom-cw-cleanup",
    "testingbucketgas",
  ]

  bucket_list_ue1 = [
    "cf-templates-1am4wkz4zazy5-us-east-1",
    "identitysandbox-gov-cloudtrail-east-s3",
    "sj2019-us-east-1-894947205914",
  ]

  # Roles from other accounts allowed to write to our archive buckets
  cross_account_archive_bucket_access = {
    "arn:aws:iam::217680906704:role/production-build-pool_gitlab_runner_role" = [
      "mhenke",
      "pauldoom",
      "int",
      "dev"
    ],
    "arn:aws:iam::034795980528:role/alpha-build-pool_gitlab_runner_role" = [
      "mhenke",
      "pauldoom"
    ]
  }

  slack_events_sns_hook_arn = "arn:aws:sns:us-west-2:894947205914:slack-otherevents"
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
    "/aws/events/gdfindings" = ""
  }
  env_name            = "sandbox-gd"
  soc_destination_arn = "arn:aws:logs:us-west-2:752281881774:destination:elp-guardduty-lg"

}

module "macie-bucket-scans-sandbox" {
  source = "../../modules/macie_v2"
  macie_scan_buckets = [
    "login-gov-pivcac-dev.894947205914-us-west-2",
    "login-gov-pivcac-int.894947205914-us-west-2",
    "login-gov-pivcac-public-cert-int.894947205914-us-west-2",
    "login-gov-pivcac-public-cert-dev.894947205914-us-west-2",
    "login-gov-log-cache-dev.894947205914-us-west-2",
    "login-gov-log-cache-int.894947205914-us-west-2",
    "login-gov.app-secrets.894947205914-us-west-2",
    "login-gov.secrets.894947205914-us-west-2"
  ]

}
output "primary_zone_dnssec_ksks" {
  value = module.main.primary_zone_dnssec_ksks
}

output "primary_zone_active_ds_value" {
  value = module.main.primary_zone_active_ds_value
}

###SES feedback notification evaluation###
module "ses_feedback_notification" {
  source                = "../../modules/eval_ses_feedback_notification"
  ses_verified_identity = "identitysandbox.gov"
}