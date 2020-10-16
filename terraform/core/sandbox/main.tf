provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["894947205914"] # require identity-sandbox
  profile             = "identitysandbox.gov"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  state_lock_table            = "terraform_locks"
  slack_sns_name              = "slack-sandbox-events" 
  root_domain                 = "identitysandbox.gov"
  mx_provider                 = "amazon-ses-inbound.us-west-2"
  sandbox_ses_inbound_enabled = 1

  bucket_list_uw2 = [
    "894947205914-awsmacietrail-dataevent",
    "894947205914-tf",
    "configrulesdevlogingov",
    "dev-s3-access-logs",
    "gsa-to3-18f-3",
    "guarddutyfireeyedemo1-gdthreatfeedoutputbucket-1lfkj1b9tcvkk",
    "guarddutythreatfeed-gdthreatfeedoutputbucket-1byh8perllwqx",
    "guarddutythreatfeed-gdthreatfeedoutputbucket-24a4k1ga8og2",
    "guarddutythreatfeed-gdthreatfeedoutputbucket-74vz0nyrf8dx",
    "ingest-threat-feed-into-gdthreatfeedoutputbucket-172rf8w89zof0",
    "ingestthreatfeedsintogua-gdthreatfeedoutputbucket-11crg9yz9gmez",
    "lg-af-test-bucket",
    "login-dot-gov-tf-state-894947205914",
    "login-gov-auth",
    "login-gov-backup-tmp-secrets",
    "login-gov-bleachbyte-logs",
    "login-gov-cloudformation",
    "login-gov-doc",
    "login-gov-jjg-analytics-secrets",
    "login-gov-kinesis-failed-events",
    "login-gov-public-artifacts-us-west-2",
    "login-gov-s3-object-logging-dev",
    "login-gov-test-coverage",
    "login-gov.scripts.lambda",
    "login-test-backup",
    "pauldoom-cw-cleanup",
    "spinnaker-config-wren",
    "testingbucketgas",
  ]

  bucket_list_ue1 = [
    "identitysandbox-gov-cloudtrail-east-s3",
    "sj2019-us-east-1-894947205914",
  ]
}

