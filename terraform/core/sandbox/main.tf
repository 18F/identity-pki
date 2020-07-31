provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["894947205914"] # require identity-sandbox
  profile             = "identitysandbox.gov"
  version             = "~> 2.37.0"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  state_lock_table            = "terraform_locks"
  slack_events_sns_hook_arn   = "arn:aws:sns:us-west-2:894947205914:identity-events"
  root_domain                 = "identitysandbox.gov"
  mx_provider                 = "amazon-ses-inbound.us-west-2"
  sandbox_ses_inbound_enabled = 1
  cloudtrail_logging_bucket   = "dev-s3-access-logs"
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
            "arn:aws:s3:::config-bucket-894947205914/",
            "arn:aws:s3:::dev-s3-access-logs/",
            "arn:aws:s3:::login-gov-cloudformation/",
            "arn:aws:s3:::login-gov-cloudtrail-894947205914/",
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

