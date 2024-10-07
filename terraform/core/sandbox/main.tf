locals {
  region     = "us-west-2"
  account_id = "894947205914"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id] # require login-sandbox
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  state_lock_table = "terraform_locks"

  sns_topic_alert_critical = "slack-events"
  sns_topic_alert_warning  = "slack-events"

  logarchive_acct_id          = "221972985980" # provide access to login-logarchive-sandbox
  logarchive_secondary_region = "us-east-1"    # disable for now

  root_domain = "identitysandbox.gov"

  # To safely rotate see https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-DNS#ksk-rotation
  dnssec_ksks = {
    # "20211005" = "old",
    "20211006" = "active"
  }

  # TODO - Remove the need for these.  Set to the same as prod
  # for now to ensure we control the target
  static_cloudfront_name     = "db1mat7gaslfp.cloudfront.net"
  developers_cloudfront_name = "d26qb7on2m22yd.cloudfront.net"
  google_site_verification_txt = [
    "04tWvC2fxF-q9hhizYUTD5vR_DqnpgpeRdN-Sy5hifo", # associated with peter.chen@gsa.gov
  ]
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

  mx_provider                          = "amazon-ses-inbound.us-west-2"
  ses_inbound_enabled                  = true
  ses_inbound_sandbox_features_enabled = true
  ses_inbound_usps_features_enabled    = true
  sandbox_email_users                  = ["smoketest-dev", "smoketest-int", "smoketest-staging", "smoketest-prod"]
  ses_inbound_usps_enabled_envs        = ["joy", "dev"]
  mta_sts_report_mailboxes             = ["tls.reports@gsa.gov", "tls-reports@login.gov"]
  mta_sts_mode                         = "enforce"

  override_cidr_blocks_v4 = [
    "72.28.3.80/32"
  ]

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
      "int",
      "dev"
    ],
    "arn:aws:iam::034795980528:role/alpha-build-pool_gitlab_runner_role" = [
      "mhenke"
    ]
  }
  enable_waf_mrg_update_notifications = true

  macie_scan_buckets = [
    "login-gov-pivcac-dev.894947205914-us-west-2",
    "login-gov-pivcac-int.894947205914-us-west-2",
    "login-gov-pivcac-public-cert-int.894947205914-us-west-2",
    "login-gov-pivcac-public-cert-dev.894947205914-us-west-2",
    "login-gov-log-cache-dev.894947205914-us-west-2",
    "login-gov-log-cache-int.894947205914-us-west-2",
    "login-gov.app-secrets.894947205914-us-west-2",
    "login-gov.secrets.894947205914-us-west-2",
  ]
}

##### REMOVE once resources are moved/imported #####

moved {
  from = module.macie-bucket-scans-sandbox.aws_macie2_account.account_scan
  to   = module.main.aws_macie2_account.account_scan
}

moved {
  from = module.macie-bucket-scans-sandbox.aws_macie2_classification_job.account_bucket_scan
  to   = module.main.aws_macie2_classification_job.account_bucket_scan
}

moved {
  from = module.macie-bucket-scans-sandbox.aws_macie2_findings_filter.account_filter
  to   = module.main.aws_macie2_findings_filter.account_filter
}

import {
  id = "/aws/macie/classificationjobs"
  to = module.main.aws_cloudwatch_log_group.macie2_classification_jobs
}

####################################################

output "primary_zone_dnssec_ksks" {
  value = module.main.primary_zone_dnssec_ksks
}

output "primary_zone_active_ds_value" {
  value = module.main.primary_zone_active_ds_value
}
