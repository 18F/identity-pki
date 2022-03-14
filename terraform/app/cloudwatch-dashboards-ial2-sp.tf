resource "aws_cloudwatch_dashboard" "idp_ial2_sp_dashboards" {
  for_each = var.idp_ial2_sp_dashboards

  dashboard_name = "${var.env_name}-SPDashboards-${each.value["agency"]}-${each.value["name"]}-IAL2Funnel"

  dashboard_body = jsonencode({
    "widgets" : [
      each.value["protocol"] == "SAML" ? {
        "height" : 9,
        "width" : 12,
        "y" : 26,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | fields @timestamp, @message\n| filter properties.service_provider = '${each.value["issuer"]}'\n| filter name = 'SAML Auth'\n| stats count_distinct(visit_id) as count by bin(10min)\n| sort @timestamp desc",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "SAML Auths",
          "view" : "timeSeries"
        }
        } : {
        "height" : 9,
        "width" : 12,
        "y" : 26,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | fields @timestamp, @message\n| filter properties.service_provider = '${each.value["issuer"]}'\n| filter name = 'OpenID Connect: authorization request'\n| stats count_distinct(visit_id) as count by bin(10min)\n| sort @timestamp desc",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "OIDC Requests",
          "view" : "timeSeries"
        }
      },
      {
        "height" : 9,
        "width" : 12,
        "y" : 26,
        "x" : 12,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | fields @timestamp, @message\n| filter properties.service_provider = '${each.value["issuer"]}'\n| filter name = 'SP redirect initiated'\n| stats count_distinct(visit_id) as count by bin(10min)\n| sort @timestamp desc",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "Redirects back to SP",
          "view" : "timeSeries"
        }
      },
      {
        "height" : 1,
        "width" : 24,
        "y" : 0,
        "x" : 0,
        "type" : "text",
        "properties" : {
          "markdown" : "\n# Funnels:\n"
        }
      },
      {
        "height" : 1,
        "width" : 24,
        "y" : 25,
        "x" : 0,
        "type" : "text",
        "properties" : {
          "markdown" : "\n# Request counts\n"
        }
      },
      {
        "height" : 1,
        "width" : 24,
        "y" : 41,
        "x" : 0,
        "type" : "text",
        "properties" : {
          "markdown" : "\n# Errors:\n"
        }
      },
      {
        "height" : 6,
        "width" : 24,
        "y" : 42,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | fields @timestamp, @message\n| filter properties.service_provider = '${each.value["issuer"]}'\n| filter (\n    (name = 'IdV: doc auth image upload vendor submitted' and !properties.event_properties.success) or\n    (name = 'Doc Auth optional submitted' and !properties.event_properties.success) or\n    (name = 'IdV: phone confirmation vendor' and !properties.event_properties.success)\n)\n| parse @message \"IdV: doc auth image upload vendor submitted\" as document_capture_error\n| parse @message \"Doc Auth optional submitted\" as verify_error\n| parse @message \"IdV: phone confirmation vendor\" as phone_error\n| stats \n    count(document_capture_error) as document_capture_error_count,\n    count(verify_error)           as verify_error_count,\n    count(phone_error)            as phone_error_count\n    by bin(10min)\n| sort @timestamp desc",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "Unsuccessful proofing vendor submissions",
          "view" : "timeSeries"
        }
      },
      {
        "height" : 6,
        "width" : 12,
        "y" : 35,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | fields @timestamp, @message\n| filter name = 'User Registration: Email Submitted'\n| filter properties.service_provider = '${each.value["issuer"]}'\n| stats count_distinct(visit_id) as count by bin(10min)",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "Email Registration Submissions",
          "view" : "timeSeries"
        }
      },
      {
        "height" : 6,
        "width" : 24,
        "y" : 7,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | fields @timestamp, @message\n| filter properties.service_provider = '${each.value["issuer"]}'\n| filter name IN ['IdV: doc auth welcome visited', 'IdV: doc auth welcome submitted', 'IdV: doc auth upload visited', 'IdV: doc auth upload submitted', 'IdV: doc auth document_capture visited', 'Frontend: IdV: front image added', 'Frontend: IdV: back image added', 'IdV: doc auth image upload vendor submitted', 'IdV: doc auth image upload vendor pii validation', 'IdV: doc auth verify visited', 'IdV: doc auth verify submitted', 'IdV: phone of record visited', 'IdV: phone confirmation vendor', 'IdV: review info visited', 'IdV: final resolution', 'Return to SP: Failed to proof'] OR (name = 'User registration: complete' and properties.event_properties.ial2)\n| filter properties.new_event = 1| stats count(visit_id) as session_count by name\n| sort session_count desc, name asc",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "Proofing Funnel - Sessions",
          "view" : "bar"
        }
      },
      {
        "height" : 6,
        "width" : 24,
        "y" : 1,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | fields @timestamp, @message\n| filter properties.service_provider = '${each.value["issuer"]}'\n| filter name IN ['IdV: doc auth welcome visited', 'IdV: doc auth welcome submitted', 'IdV: doc auth upload visited', 'IdV: doc auth upload submitted', 'IdV: doc auth document_capture visited', 'Frontend: IdV: front image added', 'Frontend: IdV: back image added', 'IdV: doc auth image upload vendor submitted', 'IdV: doc auth image upload vendor pii validation', 'IdV: doc auth verify visited', 'IdV: doc auth verify submitted', 'IdV: phone of record visited', 'IdV: phone confirmation vendor', 'IdV: review info visited', 'IdV: final resolution', 'Return to SP: Failed to proof'] OR (name = 'User registration: complete' and properties.event_properties.ial2)\n| filter properties.new_event = 1| stats count(properties.user_id) as user_count by name\n| sort user_count desc, name asc",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "Proofing Funnel - Unique Users",
          "view" : "bar"
        }
      },
      {
        "height" : 6,
        "width" : 24,
        "y" : 13,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | fields @timestamp, @message\n| filter properties.service_provider = '${each.value["issuer"]}'\n| filter name = 'Return to SP: Failed to proof'\n| stats count_distinct(visit_id) as count by bin(10min)\n| sort @timestamp desc",
          "region" : "us-west-2",
          "stacked" : false,
          "view" : "timeSeries",
          "title" : "Failed to Proof, returned to service provider"
        }
      },
      {
        "height" : 6,
        "width" : 24,
        "y" : 48,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | fields @timestamp, @message, properties.event_properties.step, properties.event_properties.errors.results.0 as error_message\n| filter name = 'IdV: doc auth image upload vendor submitted'\n| filter properties.service_provider = '${each.value["issuer"]}'\n| filter !properties.event_properties.success\n| stats count(*) as error_count by error_message\n| sort error_count desc\n",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "Primary (First) Error from Doc Auth Vendor",
          "view" : "bar"
        }
      },
      {
        "height" : 6,
        "width" : 24,
        "y" : 54,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | fields @timestamp, @message, properties.event_properties.exception as exception\n| filter name = 'IdV: doc auth image upload vendor submitted'\n| filter properties.service_provider = '${each.value["issuer"]}'\n| filter !properties.event_properties.success and !isblank(properties.event_properties.exception)\n| stats count(*) as exception_count, count_distinct(properties.user_id) as unique_users by exception\n| sort exception_count desc",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "Acuant Exceptions",
          "view" : "bar"
        }
      },
      {
        "height" : 6,
        "width" : 24,
        "y" : 19,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | fields @timestamp, properties.event_properties.source as image_capture_type, @message\n| filter properties.service_provider = '${each.value["issuer"]}'\n| filter name = 'Frontend: IdV: front image added' OR name = 'Frontend: IdV: back image added'\n| parse image_capture_type \"acuant\" as acuant\n| parse image_capture_type \"upload\" as upload\n| stats count(acuant) as acuant_count, count(upload) as upload_count, acuant_count + upload_count as total_count by bin(10min)\n| sort @timestamp desc",
          "region" : "us-west-2",
          "stacked" : false,
          "view" : "timeSeries",
          "title" : "Doc Auth image capture type"
        }
      }
    ]
  })
}
