provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["555546682965"] # require login-prod
  profile             = "login.gov"
  version             = "~> 2.67.0"
}

module "main" {
  source = "../module"

  iam_account_alias    = "login-prod"
  reports_bucket_arn   = "arn:aws:s3:::login-gov.reports.555546682965-us-west-2"
  account_roles_map = {
    iam_reports_enabled   = true
    iam_kmsadmin_enabled  = true
    iam_analytics_enabled = true
  }

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


