resource "aws_cloudwatch_dashboard" "ipp_dashboard_kpi" {
  dashboard_name = "${var.env_name}-ipp-kpi"

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
          "height" : 3,
          "width" : 13,
          "y" : 4,
          "x" : 0,
          "type" : "text",
          "properties" : {
            "markdown" : "## Proofing Results\nNumber of successfully proofed accounts through IPP"
          }
        },
        {
          "height" : 3,
          "width" : 13,
          "y" : 7,
          "x" : 0,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name = 'GetUspsProofingResultsJob: Enrollment status updated' \n| stats count(*) by properties.event_properties.passed as `Proofing Result`",
            "region" : "${var.region}",
            "stacked" : false,
            "title" : "Proofing Results",
            "view" : "table"
          }
        },
        {
          "height" : 3,
          "width" : 24,
          "y" : 14,
          "x" : 0,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE 'prod_/srv/idp/shared/log/events.log' | fields @timestamp, @message                           \n| filter name in [\n                'IdV: doc auth welcome visited',\n                'IdV: doc auth welcome submitted',\n                'IdV: doc auth agreement visited',\n                'IdV: doc auth agreement submitted',\n                'IdV: doc auth upload visited',\n                'IdV: doc auth image upload form submitted',\n                'IdV: doc auth upload submitted',\n                'IdV: doc auth image upload vendor submitted',\n                'IdV: verify in person troubleshooting option clicked',\n                'IdV: in person proofing location visited',\n                'IdV: in person proofing location submitted',\n                'IdV: in person proofing prepare submitted',\n                'IdV: in person proofing state_id submitted',\n                'IdV: in person proofing address submitted',\n                'IdV: in person proofing residential address submitted',\n                'IdV: doc auth ssn submitted',\n                'IdV: doc auth verify submitted',\n                'IdV: phone of record visited',\n                'IdV: USPS address letter requested',\n                'IdV: phone confirmation vendor',\n                'IdV: phone confirmation otp submitted',\n                'IdV: review complete',\n                'idv_enter_password_submitted',\n                'USPS IPPaaS enrollment created',\n                'IdV: personal key visited',\n                'IdV: in person ready to verify visited',\n                'GetUspsProofingResultsJob: Enrollment status updated']\n| fields    \n        (name = 'IdV: doc auth welcome visited' and properties.new_event) as @getting_started,\n        (name = 'IdV: doc auth image upload form submitted' and properties.event_properties.success and properties.new_event) as @document_authentication,\n        (name = 'IdV: doc auth image upload vendor submitted' and properties.event_properties.doc_auth_result in ['Attention','Unknown'] and properties.new_event) as @docAuth_error,\n        (name = 'IdV: verify in person troubleshooting option clicked' and properties.new_event) as @IPP_clicked,\n        (name = 'IdV: in person proofing location visited' and properties.new_event) as @view_IPP_locations,\n        (name = 'IdV: in person proofing location submitted' and properties.new_event) as @po_location_selected,\n        (name = 'IdV: in person proofing prepare submitted' and properties.new_event) as @prepared_IPP,\n        (name = 'IdV: in person proofing state_id submitted' and properties.new_event) as @ID_submitted,\n        (name = 'IdV: in person proofing state_id submitted' and properties.new_event and properties.event_properties.same_address_as_id = 0) as @addr_mismatch,\n        (name = 'IdV: in person proofing address submitted' and properties.new_event) as @pre_DAV_addr_submitted,\n        (name = 'IdV: in person proofing residential address submitted' and properties.new_event) as @residential_addr_submitted,\n        (name = 'IdV: doc auth ssn submitted' and properties.new_event and properties.event_properties.analytics_id = 'In Person Proofing') as @ssn_submitted,\n        (name = 'IdV: doc auth verify submitted' and properties.new_event and properties.event_properties.analytics_id = 'In Person Proofing') as @verify_information,\n        (name = 'IdV: phone of record visited' and properties.new_event and properties.event_properties.proofing_components.document_check = 'usps') as @verify_success,\n        (name = 'IdV: phone confirmation vendor' and properties.new_event and properties.event_properties.success = 1 and properties.event_properties.proofing_components.document_check = 'usps') as @submitted_phone,\n        (name = 'IdV: phone confirmation otp submitted' and properties.new_event and properties.event_properties.success = 1 and properties.event_properties.proofing_components.document_check = 'usps') as @submitted_otp,\n        (name = 'IdV: USPS address letter requested' and properties.new_event and properties.event_properties.resend = 0 and properties.event_properties.proofing_components.document_check = 'usps') as @requested_gpo,\n        (name in ['IdV: review complete', 'idv_enter_password_submitted'] and properties.new_event and properties.event_properties.proofing_components.document_check = 'usps') as @password_reentry,\n        (name = 'USPS IPPaaS enrollment created' and properties.new_event) as @USPS_enrollment_created,\n        (name = 'IdV: personal key visited' and properties.new_event and properties.event_properties.proofing_components.document_check = 'usps') as @personal_key,\n        substr(properties.user_id, 0, coalesce((name = 'IdV: in person ready to verify visited' and properties.new_event) * strlen(properties.user_id),0)) as @ready_verify,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated') as @visited_po,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.passed = 1) as @proofed,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.passed = 0 and properties.event_properties.reason != 'Enrollment has expired') as @failed_transaction,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.passed = 0 and properties.event_properties.reason = 'Enrollment has expired') as @expired,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.fraud_suspected = 1) as @fraud_suspected,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.secondary_id_type != 'null') as @secondary_proof \n| stats \n    sum(@getting_started) as getting_started,\n    sum(@document_authentication) as document_authentication,\n    sum(@docAuth_error) as docAuth_error,\n    sum(@IPP_clicked) as IPP_cta_clicked,\n    sum(@view_IPP_locations) as view_IPP_locations,\n    sum(@po_location_selected) as po_location_selected,\n    sum(@prepared_IPP) as prepared_IPP,\n    sum(@ID_submitted) as ID_submitted,\n    sum(@addr_mismatch) as addr_mismatch,\n    sum(@pre_DAV_addr_submitted) as addr_submitted,\n    sum(@residential_addr_submitted) as residential_addr_submitted,\n    sum(@ssn_submitted) as ssn_submitted,\n    sum(@verify_information) as verify_information,\n    sum(@verify_success) as verify_success,\n    sum(@submitted_phone) as submitted_phone,\n    sum(@submitted_otp) as submitted_otp,\n    sum(@requested_gpo) as requested_gpo,\n    sum(@password_reentry) as password_reentry,\n    sum(@USPS_enrollment_created) as enrollment_created,\n    sum(@personal_key) as personal_key,\n    greatest(count_distinct(@ready_verify) - 1,0) as ready_to_verify,\n    sum(@visited_po) - sum(@expired) as visited_po,\n    sum(@proofed) as proofed,\n    sum(@failed_transaction) as failed_transaction,\n    sum(@expired) as expired,\n    sum(@fraud_suspected) as fraud_suspected,\n    sum(@secondary_proof) as secondary_proof\n\n    by bin(1y)\n",
            "region" : "us-west-2",
            "stacked" : false,
            "title" : "E2D IPP Funnel - DAV",
            "view" : "table"
          }
        },
        {
          "height" : 4,
          "width" : 13,
          "y" : 10,
          "x" : 0,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | | filter name = 'GetUspsProofingResultsJob: Enrollment status updated'\n|  stats count(*) by properties.event_properties.fraud_suspected  as `Fraud Suspected`",
            "region" : "${var.region}",
            "stacked" : false,
            "title" : "Fraud Suspected (1 = Fraud)",
            "view" : "table"
          }
        },
        {
          "height" : 2,
          "width" : 11,
          "y" : 4,
          "x" : 13,
          "type" : "text",
          "properties" : {
            "markdown" : "## Barcode Generation Rate\nPercentage of users who clicked on the IPP CTA and successfully generated a barcode.  \n"
          }
        },
        {
          "height" : 3,
          "width" : 11,
          "y" : 6,
          "x" : 13,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name in [\n  'IdV: verify in person troubleshooting option clicked',\n  'USPS IPPaaS enrollment created']\n| fields substr(properties.user_id, 0, coalesce((name = 'IdV: verify in person troubleshooting option clicked' and properties.new_event) * strlen(properties.user_id),0)) as @in_person_proofing_started, \nname = 'USPS IPPaaS enrollment created' as @barcode_generated\n| stats sum(@barcode_generated) / greatest(count_distinct(@in_person_proofing_started) - 1,0) * 100 as barcode_generation_rate",
            "region" : "${var.region}",
            "stacked" : false,
            "title" : "Barcode Generate Rate",
            "view" : "table"
          }
        },
        {
          "height" : 2,
          "width" : 11,
          "y" : 9,
          "x" : 13,
          "type" : "text",
          "properties" : {
            "markdown" : "## Secondary Identification Used\nPercentage of users who visted a post office and used secondary identification  \n"
          }
        },
        {
          "height" : 3,
          "width" : 11
          "y" : 11,
          "x" : 13,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name = 'GetUspsProofingResultsJob: Enrollment status updated'\n| fields (properties.event_properties.secondary_id_type != 'null') as @secondary_id_type,\n(name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.new_event and properties.event_properties.reason != 'Enrollment has expired') as @po_visited\n| stats sum(@secondary_id_type) / sum (@po_visited) * 100 as transactions_secondary_id",
            "region" : "${var.region}",
            "title" : "Secondary Identification Used ",
            "view" : "table"
          }
        }
      ]
  })

}
