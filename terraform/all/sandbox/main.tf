provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["894947205914"] # require login-sandbox
  profile             = "identitysandbox.gov"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  iam_account_alias            = "login-sandbox"
  dashboard_logos_bucket_write = true
  reports_bucket_arn   = "arn:aws:s3:::login-gov.reports.894947205914-us-west-2"
  account_roles_map = {
    iam_reports_enabled   = true
    iam_kmsadmin_enabled  = true
    iam_analytics_enabled = true
  }

## TODO: confirm list of buckets to add to Intelligent Tiering,
## and remove those we don't need, before uncommenting this list.

#  legacy_bucket_list = [
#    "894947205914-awsmacietrail-dataevent",
#    "894947205914-tf",
#    "aws-athena-query-results-894947205914-us-west-2",
#    "cf-templates-1am4wkz4zazy5-us-east-1",
#    "cf-templates-1am4wkz4zazy5-us-west-2",
#    "codebuild-imagebaserole-outputbucket-k3ulvdsui2sy",
#    "codebuild-imagerailsrole-outputbucket-1apovlydy9zpm",
#    "codepipeline-imagebaserole-artifactbucket-b933g52k7fkh",
#    "codepipeline-imagerailsrole-artifactbucket-1uitjv0nh2jgy",
#    "codepipeline-us-west-2-761616215033",
#    "codesync-identitybaseimage-keybucket-ln1a6mvvs9ow",
#    "codesync-identitybaseimage-lambdazipsbucket-vhwlv2eotkhq",
#    "codesync-identitybaseimage-outputbucket-rlnx3kivn8t8",
#    "configrulesdevlogingov",
#    "cw-syn-results-894947205914-us-west-2",
#    "dev-s3-access-logs",
#    "gsa-to3-18f-3",
#    "guarddutyfireeyedemo1-gdthreatfeedoutputbucket-1lfkj1b9tcvkk",
#    "guarddutythreatfeed-gdthreatfeedoutputbucket-1byh8perllwqx",
#    "guarddutythreatfeed-gdthreatfeedoutputbucket-24a4k1ga8og2",
#    "guarddutythreatfeed-gdthreatfeedoutputbucket-74vz0nyrf8dx",
#    "identitysandbox-gov-cloudtrail-east-s3",
#    "ingest-threat-feed-into-gdthreatfeedoutputbucket-172rf8w89zof0",
#    "ingestthreatfeedsintogua-gdthreatfeedoutputbucket-11crg9yz9gmez",
#    "lg-af-test-bucket",
#    "login-dot-gov-devops.894947205914-us-west-2",
#    "login-dot-gov-secops.894947205914-us-west-2",
#    "login-dot-gov-tf-state-894947205914",
#    "login-gov-app-deployment-crissupb-894947205914-us-west-2",
#    "login-gov-auth",
#    "login-gov-backup-tmp-secrets",
#    "login-gov-bleachbyte-logs",
#    "login-gov-cloudformation",
#    "login-gov-doc",
#    "login-gov-jjg-analytics-secrets",
#    "login-gov-kinesis-failed-events",
#    "login-gov-public-artifacts-us-west-2",
#    "login-gov-rds-backup-pt2.894947205914-us-west-2",
#    "login-gov-s3-object-logging-dev",
#    "login-gov-test-coverage",
#    "login-gov.crissupb-idp-waf-logs.894947205914-us-west-2",
#    "login-gov.scripts.lambda",
#    "login-test-backup",
#    "overbridgeconfigbucket-us-west-2-894947205914",
#    "pauldoom-cw-cleanup",
#    "sj2019-us-east-1-894947205914",
#    "spinnaker-config-wren",
#    "testingbucketgas",
  ]

  cloudtrail_event_selectors  = [
    {
      include_management_events = false
      read_write_type           = "WriteOnly"

      data_resources = [
        {
          type = "AWS::S3::Object"
          values = [
            "arn:aws:s3:::894947205914-awsmacietrail-dataevent/",
            "arn:aws:s3:::cf-templates-1am4wkz4zazy5-us-west-2/",
            "arn:aws:s3:::codebuild-imagebaserole-outputbucket-k3ulvdsui2sy/",
            "arn:aws:s3:::dev-s3-access-logs/",
            "arn:aws:s3:::login-gov-cloudformation/",
            "arn:aws:s3:::login-gov.internal-certs.894947205914-us-west-2/",
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
            "arn:aws:s3",
          ]
        },
        {
          type = "AWS::Lambda::Function"
          values = [
            "arn:aws:lambda:us-west-2:894947205914:function:AWSWAFSecurityAutomations-LambdaWAFBadBotParserFun-ET6X7V1I3DM0",
            "arn:aws:lambda:us-west-2:894947205914:function:AWSWAFSecurityAutomations-LambdaWAFCustomResourceF-HKDTQ8JTMFG1",
            "arn:aws:lambda:us-west-2:894947205914:function:AWSWAFSecurityAutomations-LambdaWAFLogParserFuncti-146DZLZUWOJB8",
            "arn:aws:lambda:us-west-2:894947205914:function:AWSWAFSecurityAutomations-LambdaWAFReputationLists-1R1JGJLKECSJ8",
            "arn:aws:lambda:us-west-2:894947205914:function:AWSWAFSecurityAutomations-SolutionHelper-1S5I50MC6C8RO",
            "arn:aws:lambda:us-west-2:894947205914:function:CodeSync-IdentityBaseImag-DeleteBucketContentsLamb-1FRT9DA59TRRO",
            "arn:aws:lambda:us-west-2:894947205914:function:CodeSync-IdentityBaseImage-CopyZipsFunction-1DRZ0M4JN6212",
            "arn:aws:lambda:us-west-2:894947205914:function:CodeSync-IdentityBaseImage-CreateSSHKeyLambda-WYHZYK8MNCVP",
            "arn:aws:lambda:us-west-2:894947205914:function:CodeSync-IdentityBaseImage-GitPullLambda-1Q1M505YQ8IS7",
            "arn:aws:lambda:us-west-2:894947205914:function:CodeSync-IdentityBaseImage-ZipDlLambda-F96DI7VMXL0W",
            "arn:aws:lambda:us-west-2:894947205914:function:ConfigRulesTurnedON",
            "arn:aws:lambda:us-west-2:894947205914:function:GuardDutyFireEyeDemo1-CopyLambdaCodeFunction-1WM4760XXBY47",
            "arn:aws:lambda:us-west-2:894947205914:function:GuardDutyFireEyeDemo1-GDThreatFeedFunction-1Q5AVV8WVH7QD",
            "arn:aws:lambda:us-west-2:894947205914:function:LogsToElasticsearch_crissupb-es",
            "arn:aws:lambda:us-west-2:894947205914:function:Test",
            "arn:aws:lambda:us-west-2:894947205914:function:TestCloudWatchToSlack",
            "arn:aws:lambda:us-west-2:894947205914:function:UpdateASGWithNewAmi",
            "arn:aws:lambda:us-west-2:894947205914:function:ami_cleanup",
            "arn:aws:lambda:us-west-2:894947205914:function:brody-manual-test-slack-hook-delete-after-2018-09-01",
            "arn:aws:lambda:us-west-2:894947205914:function:crissup-test-cloudwatch",
            "arn:aws:lambda:us-west-2:894947205914:function:crissupb-test-parse-cloudwatch",
            "arn:aws:lambda:us-west-2:894947205914:function:fn_CloudTrailResponder",
            "arn:aws:lambda:us-west-2:894947205914:function:fn_ConfigRulesTurnedON",
            "arn:aws:lambda:us-west-2:894947205914:function:fn_VPCFLDetection",
            "arn:aws:lambda:us-west-2:894947205914:function:identity-idp-account-reset-notifications",
            "arn:aws:lambda:us-west-2:894947205914:function:markjordantest",
            "arn:aws:lambda:us-west-2:894947205914:function:s3-config",
            "arn:aws:lambda:us-west-2:894947205914:function:storeToS3-tmp-test",
            "arn:aws:lambda:us-west-2:894947205914:function:waf-alerts-WafLambdaFunction"
          ]
        },
      ]
    },    
  ]
}
