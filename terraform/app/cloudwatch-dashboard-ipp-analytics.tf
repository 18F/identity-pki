resource "aws_cloudwatch_dashboard" "ipp_dashboard_analytics" {
  dashboard_name = "${var.env_name}-ipp-analytics"

  dashboard_body = jsonencode(
    {
      "widgets" : [
        {
          "height" : 4,
          "width" : 24,
          "y" : 0,
          "x" : 0,
          "type" : "text",
          "properties" : {
            "markdown" : "# IPP Product Analytics Dashboard \nThis dashboard shows key product KPIs for the in-person proofing flow. \n\nYou can find more information on pilot metrics, like a cumulative funnel and USPS reporting, in the regularly updated deck: \n\n[button:Team Joy IPP Pilot Metrics](https://docs.google.com/presentation/d/1WXfGO2BGEV0O2bhcwZRTc2zDHnS-gvw-G_WolEZQbwE/edit?usp=sharing) \n"
          }
        },
        {
          "height" : 10,
          "width" : 13,
          "y" : 4,
          "x" : 11,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields\n  name,\n  @timestamp,\n  properties.event_properties.proofing_results.context.stages.threatmetrix.review_status\n| filter ispresent(properties.event_properties.proofing_results.context.stages.threatmetrix.review_status)\n|stats\n  count(properties.event_properties.proofing_results.context.stages.threatmetrix.review_status)\n  by\n  properties.event_properties.proofing_results.context.stages.threatmetrix.review_status,\n  properties.event_properties.analytics_id\n| sort properties.event_properties.analytics_id, properties.event_properties.proofing_results.context.stages.threatmetrix.review_status",
            "region" : "${var.region}",
            "stacked" : false,
            "view" : "table",
            "title" : "ThreatMetrix Comparison"
          }
        },
        {
          "height" : 5,
          "width" : 13,
          "y" : 14,
          "x" : 0,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter properties.service_provider in [\n                                         'https://eauth.va.gov/isam/sps/saml20sp/saml20',\n                                         'urn:gov:gsa:SAML:2.0.profiles:sp:sso:va_lighthouse:saml_proxy_prod',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:va_gov:internal_tools',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:RRB:myRRB']\n                                     or \n          properties.event_properties.issuer in [\n                                         'https://eauth.va.gov/isam/sps/saml20sp/saml20',\n                                         'urn:gov:gsa:SAML:2.0.profiles:sp:sso:va_lighthouse:saml_proxy_prod',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:va_gov:internal_tools',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:RRB:myRRB'] \n                                     or\n          properties.event_properties.service_provider in [\n                                         'https://eauth.va.gov/isam/sps/saml20sp/saml20',\n                                         'urn:gov:gsa:SAML:2.0.profiles:sp:sso:va_lighthouse:saml_proxy_prod',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:va_gov:internal_tools',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:RRB:myRRB']                                  \n| filter name in [\n                \n                'IdV: in person proofing address submitted']\n| stats count(*) by properties.event_properties.same_address_as_id as `Same Address as ID(1) vs Different Address(0)`",
            "region" : "${var.region}",
            "stacked" : false,
            "title" : "Count of same address vs different address",
            "view" : "table"
          }
        },
        {
          "height" : 5,
          "width" : 11,
          "y" : 14,
          "x" : 13,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, name \n| filter name = 'InPerson::EmailReminderJob: Reminder email initiated'\n| stats count(*) by properties.event_properties.email_type as `Email type`\n",
            "region" : "${var.region}",
            "title" : "Reminder Emails Sent",
            "view" : "table"
          }
        },
        {
          "height" : 2,
          "width" : 11,
          "y" : 4,
          "x" : 0,
          "type" : "text",
          "properties" : {
            "markdown" : "## Lexis Nexis / AAMVA Results \nShows users who have received results from Lexis Nexis and/or AAMVA for [further investigation](https://docs.google.com/spreadsheets/d/12WqXQRVMbGAMyPjYykl3JZXF6MU-1bTfd5zu9A2DpOc/edit#gid=0)"
          }
        },
        {
          "height" : 8,
          "width" : 11,
          "y" : 6,
          "x" : 0,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields name, @timestamp, @message\n| filter name in ['IdV: doc auth optional verify_wait submitted',\n                  'IdV: doc auth verify submitted',\n                  'IdV: doc auth verify_wait visited'] \n              and ispresent(properties.event_properties.proofing_results.context.stages.resolution.vendor_name)\n              and properties.event_properties.analytics_id = 'In Person Proofing'\n| count(*) as submits by properties.user_id\n| sort submits desc",
            "region" : "${var.region}",
            "stacked" : false,
            "title" : "Lexis Nexis / AAMVA Results",
            "view" : "table"
          }
        },
        {
          "height" : 2,
          "width" : 13,
          "y" : 36,
          "x" : 0,
          "type" : "text",
          "properties" : {
            "markdown" : "## Device Type\nShows the number device types, mobile or desktop, used to select a post office location or have generated a barcode. "
          }
        },
        {
          "height" : 3,
          "width" : 6,
          "y" : 38,
          "x" : 0,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name = 'IdV: in person proofing location submitted'\n| count(*) by properties.browser_mobile as `Desktop(0) vs Mobile(1)`",
            "region" : "${var.region}",
            "stacked" : false,
            "view" : "table",
            "title" : "Device Type @ PO Selection"
          }
        },
        {
          "height" : 3,
          "width" : 7,
          "y" : 38,
          "x" : 6,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name = 'IdV: in person ready to verify visited'\n| count(*) by properties.browser_mobile as `Desktop(0) vs Mobile(1)`",
            "region" : "${var.region}",
            "stacked" : false,
            "title" : "Device Type @ Ready to Verify",
            "view" : "table"
          }
        }
      ]
  })

}
