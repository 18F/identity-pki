resource "aws_cloudwatch_dashboard" "idp_idv_trueid_transition" {
  dashboard_name = "${var.env_name}-idp-trueid-transition"
  dashboard_body = jsonencode({
    "widgets" : [
      {
        "height" : 3,
        "width" : 24,
        "y" : 0,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | filter name = 'IdV: doc auth image upload vendor submitted'\n| fields @message, strcontains(properties.event_properties.vendor, 'Acuant') as @acuant_vendor, strcontains(properties.event_properties.vendor, 'TrueID') as @trueid_vendor\n| stats count() as Total_Submissions, \n        sum(@acuant_vendor) as Acuant_Submissions, \n        sum(@trueid_vendor) as TrueID_Submissions, \n        Acuant_Submissions/Total_Submissions*100 as Acuant_Percentage,\n        TrueID_Submissions/Total_Submissions*100 as TrueID_Percentage",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "Submission Event Total for Timeframe",
          "view" : "table"
        }
      },
      {
        "height" : 6,
        "width" : 12,
        "y" : 3,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | filter name = 'IdV: doc auth image upload vendor submitted'\n| fields @message, \n         strcontains(properties.event_properties.success, '1') as @success, \n         strcontains(properties.event_properties.success, '0') as @failure\n\n| stats sum(@success)/count()*100 as Success_Percentage,\n        sum(@failure)/count()*100 as Failed_Percentage\n        by properties.event_properties.vendor\n",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "Success & Failure Percent by Vendor",
          "view" : "bar"
        }
      },
      {
        "height" : 6,
        "width" : 12,
        "y" : 3,
        "x" : 12,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | filter name = 'IdV: doc auth image upload vendor submitted'\n| fields @message, strcontains(properties.event_properties.success, '1') as @success, strcontains(properties.event_properties.success, '0') as @failure\n| stats count() as Total_Submissions, \n        sum(@success) as Successful_Submissions, \n        sum(@failure) as Failed_Submissions\n        by properties.event_properties.vendor\n",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "Total Events by Vendor",
          "view" : "bar"
        }
      },
      {
        "height" : 6,
        "width" : 24,
        "y" : 9,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | fields @timestamp,properties.event_properties.vendor as vendor, properties.event_properties.doc_auth_result as result, properties.event_properties.success as success, @message\n| filter name = 'IdV: doc auth image upload vendor submitted'\n| parse vendor \"Acuant\" as acuant\n| parse vendor \"TrueID\" as true_id\n| stats count() as Total, count(acuant) as Acuant, count(true_id) as TrueID by bin(1h) as event_time\n| sort event_time ASC",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "Event Counts by Hour",
          "view" : "bar"
        }
      },
      {
        "height" : 6,
        "width" : 24,
        "y" : 15,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | filter name = 'IdV: doc auth image upload vendor submitted'\n| fields @message, strcontains(properties.event_properties.vendor, 'Acuant') as @acuant_vendor, strcontains(properties.event_properties.vendor, 'TrueID') as @trueid_vendor\n| stats sum(@acuant_vendor) / count() * 100 as Acuant_Percent, \n        sum(@trueid_vendor) / count() * 100 as TrueID_Percent \n        by bin(1h)",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "Vendor Percentages by Hour",
          "view" : "bar"
        }
      },
      {
        "height" : 6,
        "width" : 24,
        "y" : 21,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | filter name = 'IdV: doc auth image upload vendor submitted' AND properties.event_properties.vendor = 'Acuant'\n| fields @message, \n         strcontains(properties.event_properties.success, '1') as @success, \n         strcontains(properties.event_properties.success, '0') as @failure\n| stats sum(@success) / count() * 100 as Success_Percent, \n        sum(@failure) / count() * 100 as Failure_Percent \n        by bin(1h)\n",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "Acuant Success/Failure by Hour",
          "view" : "bar"
        }
      },
      {
        "height" : 6,
        "width" : 24,
        "y" : 27,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | filter name = 'IdV: doc auth image upload vendor submitted' AND properties.event_properties.vendor = 'TrueID'\n| fields @message, \n         strcontains(properties.event_properties.success, '1') as @success, \n         strcontains(properties.event_properties.success, '0') as @failure\n| stats sum(@success) / count() * 100 as Success_Percent, \n        sum(@failure) / count() * 100 as Failure_Percent \n        by bin(1h)\n",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "TrueID Success/Failure by Hour",
          "view" : "bar"
        }
      },
      {
        "height" : 6,
        "width" : 12,
        "y" : 33,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | filter name = 'IdV: doc auth image upload vendor submitted' AND properties.event_properties.vendor = 'Acuant'\n| stats count() as Result_Count by properties.event_properties.doc_auth_result",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "Acuant Results by Type",
          "view" : "bar"
        }
      },
      {
        "height" : 6,
        "width" : 12,
        "y" : 33,
        "x" : 12,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | filter name = 'IdV: doc auth image upload vendor submitted' AND properties.event_properties.vendor = 'TrueID'\n| stats count() as Result_Count by properties.event_properties.doc_auth_result",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "TrueID Results by Type",
          "view" : "bar"
        }
      },
      {
        "height" : 6,
        "width" : 12,
        "y" : 39,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | fields strcontains(properties.event_properties.proofing_results.context.stages.resolution.success, '1') as iv_success, \n       strcontains(properties.event_properties.proofing_results.context.stages.state_id.success, '1') as aamva_success, \n       properties.event_properties.proofing_results.context.stages.state_id.state as state, \n       @timestamp, @message\n| filter name = 'IdV: doc auth optional verify_wait submitted'\n| stats sum(iv_success) as Instant_Verify_Success, sum(aamva_success) as AAMVA_Success by bin(1h)\n| sort @timestamp desc",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "Information Verify Success by Hour",
          "view" : "timeSeries"
        }
      },
      {
        "height" : 6,
        "width" : 12,
        "y" : 39,
        "x" : 12,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | fields strcontains(properties.event_properties.proofing_results.context.stages.resolution.success, '0') as iv_failure, \n       strcontains(properties.event_properties.proofing_results.context.stages.state_id.success, '0') as aamva_failure, \n       properties.event_properties.proofing_results.context.stages.state_id.state as state, \n       @timestamp, @message\n| filter name = 'IdV: doc auth optional verify_wait submitted'\n| stats sum(iv_failure) as Instant_Verify_Failure, sum(aamva_failure) as AAMVA_Failure by bin(1h)\n| sort @timestamp desc",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "Information Verify Failure by Hour",
          "view" : "timeSeries"
        }
      }
    ]
  })
}
