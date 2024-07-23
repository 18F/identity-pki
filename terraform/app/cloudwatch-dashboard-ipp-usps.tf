resource "aws_cloudwatch_dashboard" "ipp_dashboard_usps" {
  dashboard_name = "${var.env_name}-ipp-usps"

  dashboard_body = jsonencode(
    {
      "widgets" : [
        {
          "height" : 4,
          "width" : 19,
          "y" : 0,
          "x" : 0,
          "type" : "text",
          "properties" : {
            "markdown" : "# IPP Product Analytics Dashboard \nThis dashboard shows key product KPIs for the in-person proofing flow. \n\nYou can find more information on pilot metrics, like a cumulative funnel and USPS reporting, in the regularly updated deck: \n\n[button:Team Joy IPP Pilot Metrics](https://docs.google.com/presentation/d/1WXfGO2BGEV0O2bhcwZRTc2zDHnS-gvw-G_WolEZQbwE/edit?usp=sharing) \n"
          }
        },
        {
          "height" : 2,
          "width" : 6,
          "y" : 4,
          "x" : 7,
          "type" : "text",
          "properties" : {
            "markdown" : "## Enrollments in Progress\nUsers who are \"ready to verify\" but have not yet proofed at the post office. "
          }
        },
        {
          "height" : 3,
          "width" : 6,
          "y" : 6,
          "x" : 7,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name = 'GetUspsProofingResultsJob: Job completed'\n| sort @timestamp desc\n| stats latest(properties.event_properties.enrollments_in_progress) as Enrollments_in_Progress",
            "region" : "${var.region}",
            "stacked" : false,
            "title" : "USPS - Enrollments in Progress",
            "view" : "table"
          }
        },
        {
          "height" : 2,
          "width" : 7,
          "y" : 4,
          "x" : 0,
          "type" : "text",
          "properties" : {
            "markdown" : "## Proofing Locations\nCount of proofing attempts by PO location"
          }
        },
        {
          "height" : 8,
          "width" : 7,
          "y" : 6,
          "x" : 0,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields name, @timestamp, @message\n| filter name = 'GetUspsProofingResultsJob: Enrollment status updated'\n| fields concat(properties.event_properties.proofing_post_office,', ',properties.event_properties.proofing_city,', ',properties.event_properties.proofing_state) as `po_name,city,state`\n| stats count(*) as visits by `po_name,city,state`\n| sort visits desc",
            "region" : "${var.region}",
            "stacked" : false,
            "title" : "Proofing Locations",
            "view" : "table"
          }
        },
        {
          "height" : 3,
          "width" : 6,
          "y" : 4,
          "x" : 13,
          "type" : "text",
          "properties" : {
            "markdown" : "## Post Office Visit Rate\nPercentage of users who generated a barcode and subsequently visited a post office.  Note: this is only an approximation and should be viewed over a minimum of 30 days. \n"
          }
        },
        {
          "height" : 3,
          "width" : 6,
          "y" : 7,
          "x" : 13,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name in [\n                'USPS IPPaaS enrollment created',\n                'GetUspsProofingResultsJob: Enrollment status updated']\n| fields  name = 'USPS IPPaaS enrollment created' as @ready_verify,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated' and\nproperties.new_event and properties.event_properties.reason != 'Enrollment has expired') as @visited_po\n| stats sum(@visited_po) / sum(@ready_verify) * 100 as `Post Office Visit Rate`",
            "region" : "${var.region}",
            "stacked" : false,
            "title" : "Post Office Visit Rate",
            "view" : "table"
          }
        },
        {
          "height" : 5,
          "width" : 6,
          "y" : 9,
          "x" : 7,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields name, @timestamp, @message\n| filter name in ['USPS IPPaaS enrollment failed', 'GetUspsProofingResultsJob: Exception raised']\n| stats count(*) as errors by name\n| sort errors desc",
            "region" : "${var.region}",
            "stacked" : false,
            "title" : "USPS Polling Job Errors",
            "view" : "table"
          }
        },
        {
          "height" : 4,
          "width" : 6,
          "y" : 10,
          "x" : 13,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields name, @timestamp, @message\n| filter name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.reason!='Enrollment has expired'\n| fields concat(properties.event_properties.proofing_post_office,', ',properties.event_properties.proofing_city,', ',properties.event_properties.proofing_state) as `po_name,city,state`\n| stats count_distinct(`po_name,city,state`) as unique_POs",
            "region" : "${var.region}",
            "stacked" : false,
            "title" : "Unique PO Visits",
            "view" : "table"
          }
        }
      ]
  })

}
