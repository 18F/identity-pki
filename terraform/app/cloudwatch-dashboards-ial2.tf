resource "aws_cloudwatch_dashboard" "idp_ial2_dashboard" {
  dashboard_name = "${var.env_name}-IAL2-Monitoring"

  dashboard_body = <<EOF
    {
      "widgets": [
        {
          "height": 1,
          "width": 24,
          "y": 0,
          "x": 0,
          "type": "text",
          "properties": {
            "markdown": "\n# Funnels:\n"
          }
        },
        {
          "height": 6,
          "width": 24,
          "y": 7,
          "x": 0,
          "type": "log",
          "properties": {
            "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name IN ['IdV: doc auth welcome visited', 'IdV: doc auth welcome submitted', 'IdV: doc auth upload visited', 'IdV: doc auth upload submitted', 'IdV: doc auth document_capture visited', 'Frontend: IdV: front image added', 'Frontend: IdV: back image added', 'IdV: doc auth image upload vendor submitted', 'IdV: doc auth image upload vendor pii validation', 'IdV: doc auth verify visited', 'IdV: doc auth verify submitted', 'IdV: phone of record visited', 'IdV: phone confirmation vendor', 'IdV: review info visited', 'IdV: final resolution', 'Return to SP: Failed to proof'] OR (name = 'User registration: complete' and properties.event_properties.ial2)\n| filter properties.new_event = 1| stats count(visit_id) as session_count by name\n| sort session_count desc, name asc",
            "region": "${var.region}",
            "stacked": false,
            "title": "Proofing Funnel - Sessions",
            "view": "bar"
          }
        },
        {
          "height": 6,
          "width": 24,
          "y": 1,
          "x": 0,
          "type": "log",
          "properties": {
            "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name IN ['IdV: doc auth welcome visited', 'IdV: doc auth welcome submitted', 'IdV: doc auth upload visited', 'IdV: doc auth upload submitted', 'IdV: doc auth document_capture visited', 'Frontend: IdV: front image added', 'Frontend: IdV: back image added', 'IdV: doc auth image upload vendor submitted', 'IdV: doc auth image upload vendor pii validation', 'IdV: doc auth verify visited', 'IdV: doc auth verify submitted', 'IdV: phone of record visited', 'IdV: phone confirmation vendor', 'IdV: review info visited', 'IdV: final resolution', 'Return to SP: Failed to proof'] OR (name = 'User registration: complete' and properties.event_properties.ial2)\n| filter properties.new_event = 1| stats count_distinct(properties.user_id) as user_count by name\n| sort user_count desc, name asc",
            "region": "${var.region}",
            "stacked": false,
            "title": "Proofing Funnel - Unique Users",
            "view": "bar"
          }
        },
        {
          "height": 6,
          "width": 24,
          "y": 13,
          "x": 0,
          "type": "log",
          "properties": {
            "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name = 'Return to SP: Failed to proof'\n| stats count_distinct(visit_id) as count by bin(10min)\n| sort @timestamp desc",
            "region": "${var.region}",
            "stacked": false,
            "title": "Failed to Proof, returned to service provider",
            "view": "timeSeries"
          }
        },
        {
          "height": 6,
          "width": 24,
          "y": 19,
          "x": 0,
          "type": "log",
          "properties": {
            "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, properties.event_properties.source as image_capture_type, @message\n| filter name = 'Frontend: IdV: front image added' OR name = 'Frontend: IdV: back image added'\n| parse image_capture_type \"acuant\" as acuant\n| parse image_capture_type \"upload\" as upload\n| stats count(acuant) as acuant_count, count(upload) as upload_count, acuant_count + upload_count as total_count by bin(10min)\n| sort @timestamp desc",
            "region": "${var.region}",
            "stacked": false,
            "title": "Doc Auth image capture type",
            "view": "timeSeries"
          }
        }
      ]
    }
  EOF
}
