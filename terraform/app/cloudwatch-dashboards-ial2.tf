resource "aws_cloudwatch_dashboard" "idp_ial2_dashboard" {
  dashboard_name = "${var.env_name}-IAL2-Monitoring"

  dashboard_body = jsonencode({
    "widgets" : concat(
      [{
        "height" : 6,
        "width" : 24,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${aws_cloudwatch_log_group.idp_events.name}' | fields @timestamp, @message\n| filter properties.new_event = 1\n| filter name IN ['IdV: doc auth welcome visited', 'IdV: doc auth welcome submitted', 'IdV: doc auth upload visited', 'IdV: doc auth upload submitted', 'IdV: doc auth document_capture visited', 'Frontend: IdV: front image added', 'Frontend: IdV: back image added', 'IdV: doc auth image upload vendor submitted', 'IdV: doc auth image upload vendor pii validation', 'IdV: doc auth verify visited', 'IdV: doc auth verify submitted', 'IdV: phone of record visited', 'IdV: phone confirmation vendor', 'IdV: review info visited', 'IdV: final resolution', 'Return to SP: Failed to proof', 'IdV: come back later visited']\n| stats count(*) as user_count by name\n| sort user_count desc, name asc",
          "region" : "us-west-2",
          "stacked" : false,
          "title" : "Proofing Funnel - Sessions",
          "view" : "bar"
        }
      }]
    )
  })
}
