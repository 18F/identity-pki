module "dashboard-idv-trueid-overview" {
  source = "../modules/cloudwatch_dashboard"

  dashboard_name = "${var.env_name}-idv-trueid-overview"

  ## Uncomment the filter_sps var below to add an "SP" filter to the dashboard.
  ## For this to work, you need to add the following filter to _all_ relevant queries in your dashboard:
  ##
  ##   | filter ispresent(properties.service_provider) or not ispresent(properties.service_provider)
  ##
  # filter_sps = var.idp_dashboard_filter_sps

  # dashboard_definition contains the JSON exported from Amazon Cloudwatch via bin/copy-cloudwatch-dashboard.
  # If you make changes to your dashboard, just re-run this command:
  #
  #   aws-vault exec prod-power -- bin/copy-cloudwatch-dashboard --in dprice-idp-trueid-overview --out idv-trueid-overview.tf
  #
  # Then commit your changes back to this repository.
  #
  dashboard_definition = {
    "widgets" : [
      {
        "height" : 6,
        "width" : 24,
        "y" : 5,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields properties.event_properties.vendor as vendor\n| filter name = 'IdV: doc auth image upload vendor submitted'\n| parse vendor \"TrueID\" as true_id\n| stats count(true_id) as TrueID by bin(1h) as event_time\n| sort event_time ASC",
          "region" : var.region,
          "stacked" : false,
          "title" : "Event Counts by Hour",
          "view" : "bar"
        }
      },
      {
        "height" : 6,
        "width" : 24,
        "y" : 11,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth image upload vendor submitted' AND properties.event_properties.vendor = 'TrueID'\n| fields @message, \n         strcontains(properties.event_properties.success, '1') as @success, \n         strcontains(properties.event_properties.success, '0') as @failure\n| stats sum(@success) / count() * 100 as Success_Percent, \n        sum(@failure) / count() * 100 as Failure_Percent \n        by bin(1h)\n",
          "region" : var.region,
          "stacked" : false,
          "title" : "TrueID Success/Failure by Hour",
          "view" : "bar"
        }
      },
      {
        "height" : 6,
        "width" : 12,
        "y" : 17,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth image upload vendor submitted' AND properties.event_properties.vendor = 'TrueID'\n| stats count() as Result_Count by properties.event_properties.doc_auth_result",
          "region" : var.region,
          "stacked" : false,
          "title" : "TrueID DocAuthResult by Type",
          "view" : "bar"
        }
      },
      {
        "height" : 6,
        "width" : 12,
        "y" : 29,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields strcontains(properties.event_properties.proofing_results.context.stages.resolution.success, '1') as iv_success, \n       strcontains(properties.event_properties.proofing_results.context.stages.state_id.success, '1') as aamva_success, \n       properties.event_properties.proofing_results.context.stages.state_id.state as state, \n       @timestamp, @message\n| filter name = 'IdV: doc auth verify proofing results'\n| stats sum(iv_success) as Instant_Verify_Success, sum(aamva_success) as AAMVA_Success by bin(1h)\n| sort @timestamp desc",
          "region" : var.region,
          "stacked" : false,
          "title" : "Instant Verify Success by Hour",
          "view" : "timeSeries"
        }
      },
      {
        "height" : 6,
        "width" : 12,
        "y" : 29,
        "x" : 12,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields strcontains(properties.event_properties.proofing_results.context.stages.resolution.success, '0') as iv_failure, \n       strcontains(properties.event_properties.proofing_results.context.stages.state_id.success, '0') as aamva_failure, \n       properties.event_properties.proofing_results.context.stages.state_id.state as state, \n       @timestamp, @message\n| filter name = 'IdV: doc auth verify proofing results'\n| stats sum(iv_failure) as Instant_Verify_Failure, sum(aamva_failure) as AAMVA_Failure by bin(1h)\n| sort @timestamp desc",
          "region" : var.region,
          "stacked" : false,
          "title" : "Instant Verify Failure by Hour",
          "view" : "timeSeries"
        }
      },
      {
        "height" : 6,
        "width" : 24,
        "y" : 23,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields  @timestamp, \n       (properties.event_properties.workflow = 'GSA2.TrueID.WF.CROP.PT.Prod.2') as @non_liveness_cropping, \n       (properties.event_properties.workflow = 'GSA2.TrueID.WF.PT.Prod.2') as @non_liveness_non_cropping, \n       (properties.event_properties.workflow = 'GSA2.TrueID.WF.CP.PM.Prod.2') as @liveness_cropping, \n       (properties.event_properties.workflow = 'GSA2.TrueID.WF.NC.PM.Prod.2') as @liveness_non_cropping, \n       (properties.event_properties.workflow = 'GSA2.TrueID.WF.PT.Prod.2' and properties.event_properties.transaction_status = 'passed') as @non_liveness_non_cropping_passed, \n       (properties.event_properties.workflow = 'GSA2.TrueID.WF.CROP.PT.Prod.2' and properties.event_properties.transaction_status = 'passed') as @non_liveness_cropping_passed, \n       (properties.event_properties.workflow = 'GSA2.TrueID.WF.NC.PM.Prod.2' and properties.event_properties.transaction_status = 'passed') as @liveness_non_cropping_passed, \n       (properties.event_properties.workflow = 'GSA2.TrueID.WF.CP.PM.Prod.2' and properties.event_properties.transaction_status = 'passed') as @liveness_cropping_passed \n       | filter name = 'IdV: doc auth image upload vendor submitted' and properties.event_properties.vendor = \"TrueID\" \n       | stats  \n       ((sum(@non_liveness_cropping) - sum(@non_liveness_cropping_passed))/sum(@non_liveness_cropping)) * 100 as non_liveness_cropping_fail_rate, \n       ((sum(@non_liveness_non_cropping) - sum(@non_liveness_non_cropping_passed))/sum(@non_liveness_non_cropping)) * 100 as non_liveness_non_cropping_fail_rate, \n       ((sum(@liveness_cropping) - sum(@liveness_cropping_passed))/sum(@liveness_cropping)) * 100 as liveness_cropping_fail_rate, \n       ((sum(@liveness_non_cropping) - sum(@liveness_non_cropping_passed))/sum(@liveness_non_cropping)) * 100 as liveness_non_cropping_fail_rate \n        by bin(15m)",
          "region" : var.region,
          "stacked" : false,
          "title" : "TrueID Failure Rates by Workflow",
          "view" : "timeSeries"
        }
      },
      {
        "type" : "log",
        "x" : 0,
        "y" : 0,
        "width" : 13,
        "height" : 5,
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth image upload vendor submitted'\n| fields strcontains(properties.event_properties.vendor, 'TrueID') as @trueid_vendor,\n  properties.event_properties.decision_product_status = 'pass' as @passed\n| stats count() as Total_Submissions,\n        sum(@trueid_vendor) as TrueID_Submissions,\n        sum(@passed) as Passed,\n        Passed/Total_Submissions*100 as TrueID_Success_Percentage",
          "region" : var.region,
          "stacked" : false,
          "view" : "table",
          "title" : "TrueID Success Percentage"
        }
      },
      {
        "type" : "log",
        "x" : 12,
        "y" : 17,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp,\n  properties.event_properties.portrait_match_results.FaceMatchResult as\nFaceMatchResult,\n  properties.event_properties.portrait_match_results.FaceErrorMessage as\nFaceErrorMessage\n| filter name = 'IdV: doc auth image upload vendor submitted' and FaceMatchResult = 'Fail'\n| stats count() by FaceErrorMessage\n| sort count desc",
          "region" : var.region,
          "stacked" : false,
          "view" : "table",
          "title" : "TrueID FaceMatch Failure Errors"
        }
      },
      {
        "type" : "text",
        "x" : 13,
        "y" : 0,
        "width" : 11,
        "height" : 5,
        "properties" : {
          "markdown" : "# TrueID Overview \n \nData | Definition \n----|----- \nTotal_Submissions | Total count of `IdV: doc auth image upload vendor submitted` events\nTrueID_Submissions | Count of above with vendor `TrueID`\nPassed | Count of submissions with `decision_product_status = 'pass'`"
        }
      }
    ]
  }
}
