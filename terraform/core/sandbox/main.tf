provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["894947205914"] # require identity-sandbox
  profile             = "identitysandbox.gov"
  version             = "~> 2.67.0"
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
    "cf-templates-1am4wkz4zazy5-us-west-2",
    "codebuild-imagebaserole-outputbucket-k3ulvdsui2sy",
    "codebuild-imagerailsrole-outputbucket-1apovlydy9zpm",
    "codepipeline-imagebaserole-artifactbucket-b933g52k7fkh",
    "codepipeline-imagerailsrole-artifactbucket-1uitjv0nh2jgy",
    "codepipeline-us-west-2-761616215033",
    "codesync-identitybaseimage-keybucket-ln1a6mvvs9ow",
    "codesync-identitybaseimage-lambdazipsbucket-vhwlv2eotkhq",
    "codesync-identitybaseimage-outputbucket-rlnx3kivn8t8",
    "config-bucket-894947205914",
    "configrulesdevlogingov",
    "dev-s3-access-logs",
    "gsa-to3-18f-3",
    "guarddutyfireeyedemo1-gdthreatfeedoutputbucket-1lfkj1b9tcvkk",
    "guarddutythreatfeed-gdthreatfeedoutputbucket-1byh8perllwqx",
    "guarddutythreatfeed-gdthreatfeedoutputbucket-24a4k1ga8og2",
    "guarddutythreatfeed-gdthreatfeedoutputbucket-74vz0nyrf8dx",
    "iamtestaademo",
    "ingest-threat-feed-into-gdthreatfeedoutputbucket-172rf8w89zof0",
    "ingestthreatfeedsintogua-gdthreatfeedoutputbucket-11crg9yz9gmez",
    "lg-af-test-bucket",
    "login-dot-gov-tf-state-894947205914",
    "login-gov-auth",
    "login-gov-backup-tmp-secrets",
    "login-gov-bleachbyte-logs",
    "login-gov-ci-logs",
    "login-gov-cloudformation",
    "login-gov-cloudtrail-894947205914",
    "login-gov-doc",
    "login-gov-jjg-analytics-secrets",
    "login-gov-kinesis-failed-events",
    "login-gov-public-artifacts-us-west-2",
    "login-gov-s3-object-logging-dev",
    "login-gov-test-coverage",
    "login-gov.scripts.lambda",
    "login-test-backup",
    "overbridgeconfigbucket-us-west-2-894947205914",
    "pauldoom-cw-cleanup",
    "spinnaker-config-wren",
    "testingbucketgas",
    "aws-athena-query-results-894947205914-us-west-2",
    "cw-syn-results-894947205914-us-west-2",
  ]

  bucket_list_ue1 = [
    "cf-templates-1am4wkz4zazy5-us-east-1",
    "identitysandbox-gov-cloudtrail-east-s3",
    "sj2019-us-east-1-894947205914",
  ]
}

