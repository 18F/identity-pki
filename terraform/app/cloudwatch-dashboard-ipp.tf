resource "aws_cloudwatch_dashboard" "ipp_dashboard" {
  dashboard_name = "${var.env_name}-ipp-dashboard"

  dashboard_body = jsonencode(
    {
      "widgets" : [
        {
          "height" : 6,
          "width" : 24,
          "y" : 18,
          "x" : 0,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter properties.service_provider in [\n                                         'https://eauth.va.gov/isam/sps/saml20sp/saml20',\n                                         'urn:gov:gsa:SAML:2.0.profiles:sp:sso:va_lighthouse:saml_proxy_prod',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:va_gov:internal_tools',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:RRB:myRRB',\n                                         'urn:gov:gsa:SAML:2.0.profiles.profiles:sp:sso:pbgc:mypba',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:usda:eauth']\n                                     or \n          properties.event_properties.issuer in [\n                                         'https://eauth.va.gov/isam/sps/saml20sp/saml20',\n                                         'urn:gov:gsa:SAML:2.0.profiles:sp:sso:va_lighthouse:saml_proxy_prod',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:va_gov:internal_tools',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:RRB:myRRB',\n                                         'urn:gov:gsa:SAML:2.0.profiles.profiles:sp:sso:pbgc:mypba',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:usda:eauth'] \n                                     or\n          properties.event_properties.service_provider in [\n                                         'https://eauth.va.gov/isam/sps/saml20sp/saml20',\n                                         'urn:gov:gsa:SAML:2.0.profiles:sp:sso:va_lighthouse:saml_proxy_prod',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:va_gov:internal_tools',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:RRB:myRRB',\n                                         'urn:gov:gsa:SAML:2.0.profiles.profiles:sp:sso:pbgc:mypba',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:usda:eauth']                              \n| filter name in [\n                'IdV: doc auth welcome visited',\n                'IdV: doc auth welcome submitted',\n                'IdV: doc auth agreement visited',\n                'IdV: doc auth agreement submitted',\n                'IdV: doc auth hybrid handoff visited',\n                'IdV: doc auth image upload form submitted',\n                'IdV: doc auth hybrid handoff submitted',\n                'IdV: doc auth image upload vendor submitted',\n                'IdV: verify in person troubleshooting option clicked',\n                'IdV: in person proofing location visited',\n                'IdV: in person proofing location submitted',\n                'IdV: in person proofing prepare submitted',\n                'IdV: in person proofing state_id submitted',\n                'IdV: in person proofing address submitted',\n                'IdV: doc auth ssn submitted',\n                'IdV: doc auth verify submitted',\n                'IdV: phone of record visited',\n                'IdV: USPS address letter requested',\n                'IdV: phone confirmation vendor',\n                'IdV: phone confirmation otp submitted',\n                'IdV: review complete',\n                'USPS IPPaaS enrollment created',\n                'IdV: personal key visited',\n                'IdV: in person ready to verify visited',\n                'GetUspsProofingResultsJob: Enrollment status updated']\n| fields    \n        (name = 'IdV: doc auth welcome visited' and properties.new_event) as @getting_started,\n        (name = 'IdV: doc auth image upload form submitted' and properties.event_properties.success and properties.new_event) as @document_authentication,\n        (name = 'IdV: doc auth image upload vendor submitted' and properties.event_properties.doc_auth_result in ['Attention','Unknown'] and properties.new_event) as @docAuth_error,\n        (name = 'IdV: verify in person troubleshooting option clicked' and properties.new_event) as @IPP_clicked,\n        (name = 'IdV: in person proofing location visited' and properties.new_event) as @view_IPP_locations,\n        (name = 'IdV: in person proofing location submitted' and properties.new_event) as @po_location_selected,\n        (name = 'IdV: in person proofing prepare submitted' and properties.new_event) as @prepared_IPP,\n        (name = 'IdV: in person proofing state_id submitted' and properties.new_event) as @ID_submitted,\n        (name = 'IdV: in person proofing address submitted' and properties.new_event) as @addr_submitted,\n        (name = 'IdV: doc auth ssn submitted' and properties.new_event and properties.event_properties.analytics_id = 'In Person Proofing') as @ssn_submitted,\n        (name = 'IdV: doc auth verify submitted' and properties.new_event and properties.event_properties.analytics_id = 'In Person Proofing') as @verify_information,\n        (name = 'IdV: phone of record visited' and properties.new_event and properties.event_properties.proofing_components.document_check = 'usps') as @verify_success,\n        (name = 'IdV: phone confirmation vendor' and properties.new_event and properties.event_properties.success = 1 and properties.event_properties.proofing_components.document_check = 'usps') as @submitted_phone,\n        (name = 'IdV: phone confirmation otp submitted' and properties.new_event and properties.event_properties.success = 1 and properties.event_properties.proofing_components.document_check = 'usps') as @submitted_otp,\n        (name = 'IdV: USPS address letter requested' and properties.new_event and properties.event_properties.resend = 0 and properties.event_properties.proofing_components.document_check = 'usps') as @requested_gpo,\n        (name = 'IdV: review complete' and properties.new_event and properties.event_properties.proofing_components.document_check = 'usps') as @password_reentry,\n        (name = 'USPS IPPaaS enrollment created' and properties.new_event) as @USPS_enrollment_created,\n        (name = 'IdV: personal key visited' and properties.new_event and properties.event_properties.proofing_components.document_check = 'usps') as @personal_key,\n        substr(properties.user_id, 0, coalesce((name = 'IdV: in person ready to verify visited' and properties.new_event) * strlen(properties.user_id),0)) as @ready_verify,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated') as @visited_po,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.passed = 1) as @proofed,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.passed = 0 and properties.event_properties.reason != 'Enrollment has expired') as @failed_transaction,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.passed = 0 and properties.event_properties.reason = 'Enrollment has expired') as @expired,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.fraud_suspected = 1) as @fraud_suspected,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.secondary_id_type != 'null') as @secondary_proof \n| stats \n    sum(@getting_started) as getting_started,\n    sum(@document_authentication) as document_authentication,\n    sum(@docAuth_error) as docAuth_error,\n    sum(@IPP_clicked) as IPP_cta_clicked,\n    sum(@view_IPP_locations) as view_IPP_locations,\n    sum(@po_location_selected) as po_location_selected,\n    sum(@prepared_IPP) as prepared_IPP,\n    sum(@ID_submitted) as ID_submitted,\n    sum(@addr_submitted) as addr_submitted,\n    sum(@ssn_submitted) as ssn_submitted,\n    sum(@verify_information) as verify_information,\n    sum(@verify_success) as verify_success,\n    sum(@submitted_phone) as submitted_phone,\n    sum(@submitted_otp) as submitted_otp,\n    sum(@requested_gpo) as requested_gpo,\n    sum(@password_reentry) as password_reentry,\n    sum(@USPS_enrollment_created) as enrollment_created,\n    sum(@personal_key) as personal_key,\n    greatest(count_distinct(@ready_verify) - 1,0) as ready_to_verify,\n    sum(@visited_po) - sum(@expired) as visited_po,\n    sum(@proofed) as proofed,\n    sum(@failed_transaction) as failed_transaction,\n    sum(@expired) as expired,\n    sum(@fraud_suspected) as fraud_suspected,\n    sum(@secondary_proof) as secondary_proof\n    by bin(1y)\n",
            "region" : "${var.region}",
            "stacked" : false,
            "title" : "IPP Funnel",
            "view" : "bar"
          }
        },
        {
          "height" : 3,
          "width" : 24,
          "y" : 12,
          "x" : 0,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter properties.service_provider in [\n                                         'https://eauth.va.gov/isam/sps/saml20sp/saml20',\n                                         'urn:gov:gsa:SAML:2.0.profiles:sp:sso:va_lighthouse:saml_proxy_prod',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:va_gov:internal_tools',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:RRB:myRRB',\n                                         'urn:gov:gsa:SAML:2.0.profiles.profiles:sp:sso:pbgc:mypba',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:usda:eauth']\n                                     or \n          properties.event_properties.issuer in [\n                                         'https://eauth.va.gov/isam/sps/saml20sp/saml20',\n                                         'urn:gov:gsa:SAML:2.0.profiles:sp:sso:va_lighthouse:saml_proxy_prod',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:va_gov:internal_tools',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:RRB:myRRB',\n                                         'urn:gov:gsa:SAML:2.0.profiles.profiles:sp:sso:pbgc:mypba',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:usda:eauth'] \n                                     or\n          properties.event_properties.service_provider in [\n                                         'https://eauth.va.gov/isam/sps/saml20sp/saml20',\n                                         'urn:gov:gsa:SAML:2.0.profiles:sp:sso:va_lighthouse:saml_proxy_prod',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:va_gov:internal_tools',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:RRB:myRRB',\n                                         'urn:gov:gsa:SAML:2.0.profiles.profiles:sp:sso:pbgc:mypba',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:usda:eauth']                              \n| filter name in [\n                'IdV: doc auth welcome visited',\n                'IdV: doc auth welcome submitted',\n                'IdV: doc auth agreement visited',\n                'IdV: doc auth agreement submitted',\n                'IdV: doc auth hybrid handoff visited',\n                'IdV: doc auth image upload form submitted',\n                'IdV: doc auth hybrid handoff submitted',\n                'IdV: doc auth image upload vendor submitted',\n                'IdV: verify in person troubleshooting option clicked',\n                'IdV: in person proofing location visited',\n                'IdV: in person proofing location submitted',\n                'IdV: in person proofing prepare submitted',\n                'IdV: in person proofing state_id submitted',\n                'IdV: in person proofing address submitted',\n                'IdV: doc auth ssn submitted',\n                'IdV: doc auth verify submitted',\n                'IdV: phone of record visited',\n                'IdV: USPS address letter requested',\n                'IdV: phone confirmation vendor',\n                'IdV: phone confirmation otp submitted',\n                'IdV: review complete',\n                'USPS IPPaaS enrollment created',\n                'IdV: personal key visited',\n                'IdV: in person ready to verify visited',\n                'GetUspsProofingResultsJob: Enrollment status updated']\n| fields    \n        (name = 'IdV: doc auth welcome visited' and properties.new_event) as @getting_started,\n        (name = 'IdV: doc auth image upload form submitted' and properties.event_properties.success and properties.new_event) as @document_authentication,\n        (name = 'IdV: doc auth image upload vendor submitted' and properties.event_properties.doc_auth_result in ['Attention','Unknown'] and properties.new_event) as @docAuth_error,\n        (name = 'IdV: verify in person troubleshooting option clicked' and properties.new_event) as @IPP_clicked,\n        (name = 'IdV: in person proofing location visited' and properties.new_event) as @view_IPP_locations,\n        (name = 'IdV: in person proofing location submitted' and properties.new_event) as @po_location_selected,\n        (name = 'IdV: in person proofing prepare submitted' and properties.new_event) as @prepared_IPP,\n        (name = 'IdV: in person proofing state_id submitted' and properties.new_event) as @ID_submitted,\n        (name = 'IdV: in person proofing address submitted' and properties.new_event) as @addr_submitted,\n        (name = 'IdV: doc auth ssn submitted' and properties.new_event and properties.event_properties.analytics_id = 'In Person Proofing') as @ssn_submitted,\n        (name = 'IdV: doc auth verify submitted' and properties.new_event and properties.event_properties.analytics_id = 'In Person Proofing') as @verify_information,\n        (name = 'IdV: phone of record visited' and properties.new_event and properties.event_properties.proofing_components.document_check = 'usps') as @verify_success,\n        (name = 'IdV: phone confirmation vendor' and properties.new_event and properties.event_properties.success = 1 and properties.event_properties.proofing_components.document_check = 'usps') as @submitted_phone,\n        (name = 'IdV: phone confirmation otp submitted' and properties.new_event and properties.event_properties.success = 1 and properties.event_properties.proofing_components.document_check = 'usps') as @submitted_otp,\n        (name = 'IdV: USPS address letter requested' and properties.new_event and properties.event_properties.resend = 0 and properties.event_properties.proofing_components.document_check = 'usps') as @requested_gpo,\n        (name = 'IdV: review complete' and properties.new_event and properties.event_properties.proofing_components.document_check = 'usps') as @password_reentry,\n        (name = 'USPS IPPaaS enrollment created' and properties.new_event) as @USPS_enrollment_created,\n        (name = 'IdV: personal key visited' and properties.new_event and properties.event_properties.proofing_components.document_check = 'usps') as @personal_key,\n        substr(properties.user_id, 0, coalesce((name = 'IdV: in person ready to verify visited' and properties.new_event) * strlen(properties.user_id),0)) as @ready_verify,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated') as @visited_po,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.passed = 1) as @proofed,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.passed = 0 and properties.event_properties.reason != 'Enrollment has expired') as @failed_transaction,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.passed = 0 and properties.event_properties.reason = 'Enrollment has expired') as @expired,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.fraud_suspected = 1) as @fraud_suspected,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.secondary_id_type != 'null') as @secondary_proof \n| stats \n    sum(@getting_started) as getting_started,\n    sum(@document_authentication) as document_authentication,\n    sum(@docAuth_error) as docAuth_error,\n    sum(@IPP_clicked) as IPP_cta_clicked,\n    sum(@view_IPP_locations) as view_IPP_locations,\n    sum(@po_location_selected) as po_location_selected,\n    sum(@prepared_IPP) as prepared_IPP,\n    sum(@ID_submitted) as ID_submitted,\n    sum(@addr_submitted) as addr_submitted,\n    sum(@ssn_submitted) as ssn_submitted,\n    sum(@verify_information) as verify_information,\n    sum(@verify_success) as verify_success,\n    sum(@submitted_phone) as submitted_phone,\n    sum(@submitted_otp) as submitted_otp,\n    sum(@requested_gpo) as requested_gpo,\n    sum(@password_reentry) as password_reentry,\n    sum(@USPS_enrollment_created) as enrollment_created,\n    sum(@personal_key) as personal_key,\n    greatest(count_distinct(@ready_verify) - 1,0) as ready_to_verify,\n    sum(@visited_po) - sum(@expired) as visited_po,\n    sum(@proofed) as proofed,\n    sum(@failed_transaction) as failed_transaction,\n    sum(@expired) as expired,\n    sum(@fraud_suspected) as fraud_suspected,\n    sum(@secondary_proof) as secondary_proof\n    by bin(1y)\n",
            "region" : "${var.region}",
            "stacked" : false,
            "title" : "E2E IPP Funnel - For Reporting",
            "view" : "table"
          }
        },
        {
          "height" : 3,
          "width" : 24,
          "y" : 27,
          "x" : 0,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name in [\n                 'IdV: verify in person troubleshooting option clicked',\n                 'IdV: in person proofing location visited',\n                 'IdV: in person proofing location submitted',\n                 'IdV: in person proofing prepare submitted',\n                 'IdV: in person proofing verify submitted',\n                 'USPS IPPaaS enrollment created',\n                 'IdV: in person ready to verify visited',\n                 'GetUspsProofingResultsJob: Enrollment status updated']\n| fields    \n         (name = 'IdV: verify in person troubleshooting option clicked' and properties.new_event) as @IPP_clicked,\n         (name = 'IdV: in person proofing location visited' and properties.new_event) as @view_IPP_locations,\n         (name = 'IdV: in person proofing location submitted' and properties.new_event) as @po_location_selected,\n         (name = 'USPS IPPaaS enrollment created' and properties.new_event) as @enrollment_created,\n         substr(properties.user_id, 0, coalesce((name = 'IdV: in person ready to verify visited' and properties.new_event) * strlen(properties.user_id),0)) as @ready_verify,\n         substr(properties.user_id, 0, coalesce((name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.new_event and properties.event_properties.passed) * strlen(properties.user_id),0)) as @proofed,\n         substr(properties.user_id, 0, coalesce((name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.new_event and properties.event_properties.passed = 0) * strlen(properties.user_id),0)) as @failed_transaction\n| stats\n     sum(@IPP_clicked) as Total_users_that_clicked_on_the_IPP_call_to_action_link,\n     sum(@view_IPP_locations) as Total_users_that_viewed_the_locations_page,\n     sum(@po_location_selected) as Total_users_that_selected_a_PO,\n     sum(@enrollment_created) as enrollment_created,\n     greatest(count_distinct(@ready_verify) - 1,0) as ready_to_verify,\n     greatest(count_distinct(@proofed) - 1,0) as proofed,\n     greatest(count_distinct(@failed_transaction) - 1,0) as failed_transaction\n",
            "region" : "${var.region}",
            "stacked" : false,
            "title" : "USPS Reporting - Funnel",
            "view" : "table"
          }
        },
        {
          "height" : 3,
          "width" : 6,
          "y" : 32,
          "x" : 18,
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
          "height" : 6,
          "width" : 18,
          "y" : 30,
          "x" : 0,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter properties.new_session_success_state = 1\n| filter ispresent(properties.session_duration)\n| filter name in [‘IdV: verify in person troubleshooting option clicked’,\n                ‘IdV: in person proofing location submitted’,\n                ‘IdV: in person proofing prepare submitted’,\n                ‘IdV: in person proofing state_id submitted’,\n                ‘IdV: in person proofing address submitted’,\n                ‘IdV: in person proofing ssn submitted’,\n                ‘IdV: in person proofing verify submitted’,\n                'IdV: in person ready to verify visited']\nor (name in ['IdV: doc auth ssn submitted','IdV: doc auth verify submitted'] and properties.event_properties.analytics_id = 'In Person Proofing')\n| stats min(properties.session_duration) as `Min Time`, max(properties.session_duration) as `Max Time`, avg(properties.session_duration) as `Average Time It Takes To Get To Step (seconds)`, count(*) by name as Step\n| sort `Average Time It Takes To Get To Step (seconds)` asc\n",
            "region" : "${var.region}",
            "stacked" : false,
            "title" : "Elapsed Time",
            "view" : "table"
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
        },
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
          "height" : 8,
          "width" : 18,
          "y" : 4,
          "x" : 0,
          "type" : "text",
          "properties" : {
            "markdown" : "## IPP Funnel\nThis IPP funnel shows the number of users who have viewed a given step in the IPP flow.\n\n- **In Pilot State** is the number of users in VA, MD, DC. Note this isn’t a criteria to click into IPP, but helps us get a sense of how many people are in the approximate area.\n- **IPP CTA Clicked** is the number of users who clicked the “new feature” call to action \n- **View IPP Locations** is the number of users who viewed the page that lists the 7 post office pilot locations\n- **Prepared IPP** is the number of users who viewed the workflow preparation page\n- **PO Location Selected** is the number of users who selected a location\n- **ID Submitted** is the number of users who entered their ID information\n- **Address Submitted** is the number of users who entered their current address information\n- **SSN Submitted** is the number of users who entered their SSN\n- **Verify Information** is the number of users who confirmed their personal data and submitted their information to LexisNexis / AAMVA for identity verification\n- **Enrollment Created** is the number of users who generated a barcode\n- **Ready to Verify** is the number of users who visited the ready to verify page\n- **Proofed** is the number of users who successfully received a proof result from USPS\n"
          }
        },
        {
          "height" : 3,
          "width" : 6,
          "y" : 6,
          "x" : 18,
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
          "height" : 2,
          "width" : 6,
          "y" : 35,
          "x" : 18,
          "type" : "text",
          "properties" : {
            "markdown" : "## Barcode Generation Rate\nPercentage of users who clicked on the IPP CTA and successfully generated a barcode.  \n"
          }
        },
        {
          "height" : 2,
          "width" : 6,
          "y" : 30,
          "x" : 18,
          "type" : "text",
          "properties" : {
            "markdown" : "## Enrollments in Progress\nUsers who are \"ready to verify\" but have not yet proofed at the post office. "
          }
        },
        {
          "height" : 3,
          "width" : 6,
          "y" : 40,
          "x" : 18,
          "type" : "text",
          "properties" : {
            "markdown" : "## Post Office Visit Rate\nPercentage of users who generated a barcode and subsequently visited a post office.  Note: this is only an approximation and should be viewed over a minimum of 30 days. \n"
          }
        },
        {
          "height" : 3,
          "width" : 6,
          "y" : 43,
          "x" : 18,
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
          "height" : 2,
          "width" : 6,
          "y" : 4,
          "x" : 18,
          "type" : "text",
          "properties" : {
            "markdown" : "## Proofing Results\nNumber of successfully proofed accounts through IPP"
          }
        },
        {
          "height" : 3,
          "width" : 6,
          "y" : 37,
          "x" : 18,
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
          "height" : 3,
          "width" : 5,
          "y" : 38,
          "x" : 13,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name = 'GetUspsProofingResultsJob: Enrollment status updated'\n| fields (properties.event_properties.secondary_id_type != 'null') as @secondary_id_type,\n(name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.new_event and properties.event_properties.reason != 'Enrollment has expired') as @po_visited\n| stats sum(@secondary_id_type) / sum (@po_visited) * 100 as transactions_secondary_id",
            "region" : "${var.region}",
            "title" : "Secondary Identification Used ",
            "view" : "table"
          }
        },
        {
          "height" : 2,
          "width" : 5,
          "y" : 36,
          "x" : 13,
          "type" : "text",
          "properties" : {
            "markdown" : "## Secondary Identification Used\nPercentage of users who visted a post office and used secondary identification  \n"
          }
        },
        {
          "height" : 2,
          "width" : 11,
          "y" : 41,
          "x" : 0,
          "type" : "text",
          "properties" : {
            "markdown" : "## Lexis Nexis / AAMVA Results \nShows users who have received results from Lexis Nexis and/or AAMVA for [further investigation](https://docs.google.com/spreadsheets/d/12WqXQRVMbGAMyPjYykl3JZXF6MU-1bTfd5zu9A2DpOc/edit#gid=0)"
          }
        },
        {
          "height" : 8,
          "width" : 11,
          "y" : 43,
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
          "width" : 7,
          "y" : 41,
          "x" : 11,
          "type" : "text",
          "properties" : {
            "markdown" : "## Proofing Locations\nCount of proofing attempts by PO location"
          }
        },
        {
          "height" : 8,
          "width" : 7,
          "y" : 43,
          "x" : 11,
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
          "height" : 4,
          "width" : 6,
          "y" : 46,
          "x" : 18,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields name, @timestamp, @message\n| filter name in ['USPS IPPaaS enrollment failed', 'GetUspsProofingResultsJob: Exception raised']\n| count(*) as errors by name\n| sort errors desc",
            "region" : "${var.region}",
            "stacked" : false,
            "title" : "USPS Polling Job Errors",
            "view" : "table"
          }
        },
        {
          "height" : 3,
          "width" : 6,
          "y" : 9,
          "x" : 18,
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
          "height" : 6,
          "width" : 18,
          "y" : 51,
          "x" : 0,
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
          "height" : 3,
          "width" : 24,
          "y" : 24,
          "x" : 0,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter properties.service_provider in [\n                                         'https://eauth.va.gov/isam/sps/saml20sp/saml20',\n                                         'urn:gov:gsa:SAML:2.0.profiles:sp:sso:va_lighthouse:saml_proxy_prod',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:va_gov:internal_tools',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:RRB:myRRB']\n                                     or \n          properties.event_properties.issuer in [\n                                         'https://eauth.va.gov/isam/sps/saml20sp/saml20',\n                                         'urn:gov:gsa:SAML:2.0.profiles:sp:sso:va_lighthouse:saml_proxy_prod',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:va_gov:internal_tools',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:RRB:myRRB'] \n                                     or\n          properties.event_properties.service_provider in [\n                                         'https://eauth.va.gov/isam/sps/saml20sp/saml20',\n                                         'urn:gov:gsa:SAML:2.0.profiles:sp:sso:va_lighthouse:saml_proxy_prod',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:va_gov:internal_tools',\n                                         'urn:gov:gsa:openidconnect.profiles:sp:sso:RRB:myRRB']                                  \n| filter name in [\n                'IdV: doc auth welcome visited',\n                'IdV: doc auth welcome submitted',\n                'IdV: doc auth agreement visited',\n                'IdV: doc auth agreement submitted',\n                'IdV: doc auth hybrid handoff visited',\n                'IdV: doc auth image upload form submitted',\n                'IdV: doc auth hybrid handoff submitted',\n                'IdV: doc auth image upload vendor submitted',\n                'IdV: verify in person troubleshooting option clicked',\n                'IdV: in person proofing location visited',\n                'IdV: in person proofing location submitted',\n                'IdV: in person proofing prepare submitted',\n                'IdV: in person proofing state_id submitted',\n                'IdV: in person proofing address submitted',\n                'IdV: doc auth ssn submitted',\n                'IdV: doc auth verify submitted',\n                'IdV: phone of record visited',\n                'IdV: USPS address letter requested',\n                'IdV: phone confirmation vendor',\n                'IdV: phone confirmation otp submitted',\n                'IdV: review complete',\n                'USPS IPPaaS enrollment created',\n                'IdV: personal key visited',\n                'IdV: in person ready to verify visited',\n                'GetUspsProofingResultsJob: Enrollment status updated']\n| fields    \n        (name = 'IdV: doc auth welcome visited' and properties.new_event) as @getting_started,\n        (name = 'IdV: doc auth image upload form submitted' and properties.event_properties.success and properties.new_event) as @document_authentication,\n        (name = 'IdV: doc auth image upload vendor submitted' and properties.event_properties.doc_auth_result in ['Attention','Unknown'] and properties.new_event) as @docAuth_error,\n        (name = 'IdV: verify in person troubleshooting option clicked' and properties.new_event) as @IPP_clicked,\n        (name = 'IdV: in person proofing location visited' and properties.new_event) as @view_IPP_locations,\n        (name = 'IdV: in person proofing location submitted' and properties.new_event) as @po_location_selected,\n        (name = 'IdV: in person proofing prepare submitted' and properties.new_event) as @prepared_IPP,\n        (name = 'IdV: in person proofing state_id submitted' and properties.new_event) as @ID_submitted,\n        (name = 'IdV: in person proofing address submitted' and properties.new_event) as @addr_submitted,\n        (name = 'IdV: doc auth ssn submitted' and properties.new_event and properties.event_properties.analytics_id = 'In Person Proofing') as @ssn_submitted,\n        (name = 'IdV: doc auth verify submitted' and properties.new_event and properties.event_properties.analytics_id = 'In Person Proofing') as @verify_information,\n        (name = 'IdV: phone of record visited' and properties.new_event and properties.event_properties.proofing_components.document_check = 'usps') as @verify_success,\n        (name = 'IdV: phone confirmation vendor' and properties.new_event and properties.event_properties.success = 1 and properties.event_properties.proofing_components.document_check = 'usps') as @submitted_phone,\n        (name = 'IdV: phone confirmation otp submitted' and properties.new_event and properties.event_properties.success = 1 and properties.event_properties.proofing_components.document_check = 'usps') as @submitted_otp,\n        (name = 'IdV: USPS address letter requested' and properties.new_event and properties.event_properties.resend = 0 and properties.event_properties.proofing_components.document_check = 'usps') as @requested_gpo,\n        (name = 'IdV: review complete' and properties.new_event and properties.event_properties.proofing_components.document_check = 'usps') as @password_reentry,\n        (name = 'USPS IPPaaS enrollment created' and properties.new_event) as @USPS_enrollment_created,\n        (name = 'IdV: personal key visited' and properties.new_event and properties.event_properties.proofing_components.document_check = 'usps') as @personal_key,\n        substr(properties.user_id, 0, coalesce((name = 'IdV: in person ready to verify visited' and properties.new_event) * strlen(properties.user_id),0)) as @ready_verify,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated') as @visited_po,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.passed = 1) as @proofed,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.passed = 0 and properties.event_properties.reason != 'Enrollment has expired') as @failed_transaction,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.passed = 0 and properties.event_properties.reason = 'Enrollment has expired') as @expired,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.fraud_suspected = 1) as @fraud_suspected,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.secondary_id_type != 'null') as @secondary_proof \n| stats \n    sum(@getting_started) as getting_started,\n    sum(@document_authentication) as document_authentication,\n    sum(@docAuth_error) as docAuth_error,\n    sum(@IPP_clicked) as IPP_cta_clicked,\n    sum(@view_IPP_locations) as view_IPP_locations,\n    sum(@po_location_selected) as po_location_selected,\n    sum(@prepared_IPP) as prepared_IPP,\n    sum(@ID_submitted) as ID_submitted,\n    sum(@addr_submitted) as addr_submitted,\n    sum(@ssn_submitted) as ssn_submitted,\n    sum(@verify_information) as verify_information,\n    sum(@verify_success) as verify_success,\n    sum(@submitted_phone) as submitted_phone,\n    sum(@submitted_otp) as submitted_otp,\n    sum(@requested_gpo) as requested_gpo,\n    sum(@password_reentry) as password_reentry,\n    sum(@USPS_enrollment_created) as enrollment_created,\n    sum(@personal_key) as personal_key,\n    greatest(count_distinct(@ready_verify) - 1,0) as ready_to_verify,\n    sum(@visited_po) - sum(@expired) as visited_po,\n    sum(@proofed) as proofed,\n    sum(@failed_transaction) as failed_transaction,\n    sum(@expired) as expired,\n    sum(@fraud_suspected) as fraud_suspected,\n    sum(@secondary_proof) as secondary_proof\n    by bin(1w)",
            "region" : "${var.region}",
            "stacked" : false,
            "title" : "E2E IPP Funnel WoW",
            "view" : "table"
          }
        },
        {
          "height" : 5,
          "width" : 13,
          "y" : 57,
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
          "height" : 4,
          "width" : 6,
          "y" : 50,
          "x" : 18,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields name, @timestamp, @message\n| filter name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.reason!='Enrollment has expired'\n| fields concat(properties.event_properties.proofing_post_office,', ',properties.event_properties.proofing_city,', ',properties.event_properties.proofing_state) as `po_name,city,state`\n| stats count_distinct(`po_name,city,state`) as unique_POs",
            "region" : "${var.region}",
            "stacked" : false,
            "title" : "Unique PO Visits",
            "view" : "table"
          }
        },
        {
          "height" : 5,
          "width" : 11,
          "y" : 57,
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
          "height" : 3,
          "width" : 24,
          "y" : 15,
          "x" : 0,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message                           \n| filter name in [\n                'IdV: doc auth welcome visited',\n                'IdV: doc auth welcome submitted',\n                'IdV: doc auth agreement visited',\n                'IdV: doc auth agreement submitted',\n                'IdV: doc auth hybrid handoff visited',\n                'IdV: doc auth image upload form submitted',\n                'IdV: doc auth hybrid handoff submitted',\n                'IdV: doc auth image upload vendor submitted',\n                'IdV: verify in person troubleshooting option clicked',\n                'IdV: in person proofing location visited',\n                'IdV: in person proofing location submitted',\n                'IdV: in person proofing prepare submitted',\n                'IdV: in person proofing state_id submitted',\n                'IdV: in person proofing address submitted',\n                'IdV: doc auth ssn submitted',\n                'IdV: doc auth verify submitted',\n                'IdV: phone of record visited',\n                'IdV: USPS address letter requested',\n                'IdV: phone confirmation vendor',\n                'IdV: phone confirmation otp submitted',\n                'IdV: review complete',\n                'USPS IPPaaS enrollment created',\n                'IdV: personal key visited',\n                'IdV: in person ready to verify visited',\n                'GetUspsProofingResultsJob: Enrollment status updated']\n| fields    \n        (name = 'IdV: doc auth welcome visited' and properties.new_event) as @getting_started,\n        (name = 'IdV: doc auth image upload form submitted' and properties.event_properties.success and properties.new_event) as @document_authentication,\n        (name = 'IdV: doc auth image upload vendor submitted' and properties.event_properties.doc_auth_result in ['Attention','Unknown'] and properties.new_event) as @docAuth_error,\n        (name = 'IdV: verify in person troubleshooting option clicked' and properties.new_event) as @IPP_clicked,\n        (name = 'IdV: in person proofing location visited' and properties.new_event) as @view_IPP_locations,\n        (name = 'IdV: in person proofing location submitted' and properties.new_event) as @po_location_selected,\n        (name = 'IdV: in person proofing prepare submitted' and properties.new_event) as @prepared_IPP,\n        (name = 'IdV: in person proofing state_id submitted' and properties.new_event) as @ID_submitted,\n        (name = 'IdV: in person proofing address submitted' and properties.new_event) as @addr_submitted,\n        (name = 'IdV: doc auth ssn submitted' and properties.new_event and properties.event_properties.analytics_id = 'In Person Proofing') as @ssn_submitted,\n        (name = 'IdV: doc auth verify submitted' and properties.new_event and properties.event_properties.analytics_id = 'In Person Proofing') as @verify_information,\n        (name = 'IdV: phone of record visited' and properties.new_event and properties.event_properties.proofing_components.document_check = 'usps') as @verify_success,\n        (name = 'IdV: phone confirmation vendor' and properties.new_event and properties.event_properties.success = 1 and properties.event_properties.proofing_components.document_check = 'usps') as @submitted_phone,\n        (name = 'IdV: phone confirmation otp submitted' and properties.new_event and properties.event_properties.success = 1 and properties.event_properties.proofing_components.document_check = 'usps') as @submitted_otp,\n        (name = 'IdV: USPS address letter requested' and properties.new_event and properties.event_properties.resend = 0 and properties.event_properties.proofing_components.document_check = 'usps') as @requested_gpo,\n        (name = 'IdV: review complete' and properties.new_event and properties.event_properties.proofing_components.document_check = 'usps') as @password_reentry,\n        (name = 'USPS IPPaaS enrollment created' and properties.new_event) as @USPS_enrollment_created,\n        (name = 'IdV: personal key visited' and properties.new_event and properties.event_properties.proofing_components.document_check = 'usps') as @personal_key,\n        substr(properties.user_id, 0, coalesce((name = 'IdV: in person ready to verify visited' and properties.new_event) * strlen(properties.user_id),0)) as @ready_verify,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated') as @visited_po,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.passed = 1) as @proofed,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.passed = 0 and properties.event_properties.reason != 'Enrollment has expired') as @failed_transaction,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.passed = 0 and properties.event_properties.reason = 'Enrollment has expired') as @expired,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.fraud_suspected = 1) as @fraud_suspected,\n        (name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.secondary_id_type != 'null') as @secondary_proof \n| stats \n    sum(@getting_started) as getting_started,\n    sum(@document_authentication) as document_authentication,\n    sum(@docAuth_error) as docAuth_error,\n    sum(@IPP_clicked) as IPP_cta_clicked,\n    sum(@view_IPP_locations) as view_IPP_locations,\n    sum(@po_location_selected) as po_location_selected,\n    sum(@prepared_IPP) as prepared_IPP,\n    sum(@ID_submitted) as ID_submitted,\n    sum(@addr_submitted) as addr_submitted,\n    sum(@ssn_submitted) as ssn_submitted,\n    sum(@verify_information) as verify_information,\n    sum(@verify_success) as verify_success,\n    sum(@submitted_phone) as submitted_phone,\n    sum(@submitted_otp) as submitted_otp,\n    sum(@requested_gpo) as requested_gpo,\n    sum(@password_reentry) as password_reentry,\n    sum(@USPS_enrollment_created) as enrollment_created,\n    sum(@personal_key) as personal_key,\n    greatest(count_distinct(@ready_verify) - 1,0) as ready_to_verify,\n    sum(@visited_po) - sum(@expired) as visited_po,\n    sum(@proofed) as proofed,\n    sum(@failed_transaction) as failed_transaction,\n    sum(@expired) as expired,\n    sum(@fraud_suspected) as fraud_suspected,\n    sum(@secondary_proof) as secondary_proof\n    by bin(1y)\n",
            "region" : "${var.region}",
            "stacked" : false,
            "title" : "E2E IPP Funnel - No SP Filter",
            "view" : "table"
          }
        }
      ]
  })

}
