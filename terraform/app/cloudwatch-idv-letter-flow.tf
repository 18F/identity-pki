resource "aws_cloudwatch_dashboard" "idv_letter_flow" {
  dashboard_name = "${var.env_name}-idv-letter-flow"

  dashboard_body = <<EOF
    {
  "start": "-PT720H",
  "widgets": [
    {
      "height": 9,
      "width": 24,
      "y": 6,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name in ['IdV: phone confirmation otp submitted', 'IdV: USPS address letter requested']\n| fields (name = 'IdV: phone confirmation otp submitted' and properties.event_properties.success) as @phone_confirmed,\n  (name = 'IdV: USPS address letter requested' and\n!properties.event_properties.resend) as @letter_requested\n| stats sum(@letter_requested) / (sum(@phone_confirmed) + sum(@letter_requested)) * 100 as letter_requested,\n  sum(@phone_confirmed) / (sum(@phone_confirmed) + sum(@letter_requested))\n* 100 as phone_selected\n  by bin(1day)",
        "region": "${var.region}",
        "stacked": true,
        "title": "Phone address confirmation vs GPO address letter requests (not including resend requests)",
        "view": "timeSeries"
      }
    },
    {
      "height": 11,
      "width": 18,
      "y": 15,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name = 'IdV: USPS address letter requested' and !properties.event_properties.resend\n| stats count() as count by bin(1day) as period\n| sort period asc",
        "region": "${var.region}",
        "stacked": false,
        "title": "GPO letter requested counts (not including resends)",
        "view": "bar"
      }
    },
    {
      "height": 10,
      "width": 18,
      "y": 26,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter (name = 'IdV: GPO verification submitted' and properties.event_properties.success) or name = 'IdV: USPS address letter enqueued'\n| fields (name = 'IdV: GPO verification submitted') as @confirmed,\n  (name = 'IdV: USPS address letter enqueued' and\n!properties.event_properties.resend) as @sent\n| parse properties.event_properties.enqueued_at '*T*' @enqueued_at_day, @enqueued_at_time\n| stats sum(@sent) as sent, sum(@confirmed) as confirmed by @enqueued_at_day\n| sort @enqueued_at_day asc",
        "region": "${var.region}",
        "stacked": false,
        "title": "Letter send and confirmation by enqueued at (including resends)",
        "view": "bar"
      }
    },
    {
      "height": 11,
      "width": 6,
      "y": 15,
      "x": 18,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name = 'IdV: USPS address letter requested' and !properties.event_properties.resend\n| stats count() as count",
        "region": "${var.region}",
        "stacked": false,
        "title": "Total letter request counts (not including resends)",
        "view": "table"
      }
    },
    {
      "height": 10,
      "width": 6,
      "y": 26,
      "x": 18,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter (name = 'IdV: GPO verification submitted' and properties.event_properties.success) or name = 'IdV: USPS address letter enqueued'\n| fields (name = 'IdV: GPO verification submitted') as @confirmed,\n  (name = 'IdV: USPS address letter enqueued' and\n!properties.event_properties.resend) as @sent\n| parse properties.event_properties.enqueued_at '*T*' @enqueued_at_day, @enqueued_at_time\n| stats sum(@confirmed) / sum(@sent) * 100 as success_rate, sum(@sent) as total_sent, sum(@confirmed) as total_confirmed",
        "region": "${var.region}",
        "stacked": false,
        "title": "Letter send and confirmation stats (including resends)",
        "view": "table"
      }
    },
    {
      "type": "log",
      "x": 0,
      "y": 0,
      "width": 24,
      "height": 6,
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name in ['IdV: USPS address visited', 'IdV: USPS address letter requested', 'IdV: USPS address letter enqueued', 'IdV: GPO verification visited', 'IdV: GPO verification submitted']\n| fields (name = 'IdV: USPS address visited' and properties.new_event) as @letter_request_visited,\n  (name = 'IdV: USPS address letter requested' and\n!properties.event_properties.resend and properties.new_event) as @letter_request_submitted,\n  (name = 'IdV: USPS address letter enqueued' and\n!properties.event_properties.resend) as @letter_enqueued,\n  (name = 'IdV: GPO verification visited' and properties.new_event) as\n@code_verification_visited,\n  (name = 'IdV: GPO verification submitted' and\nproperties.event_properties.success and properties.new_event) as @code_verification_submitted_success\n| stats sum(@letter_request_visited) as letter_request_visited,\n  sum(@letter_request_submitted) as letter_request_submitted,\n  sum(@letter_enqueued) as letter_enqueued,\n  sum(@code_verification_visited) as code_verification_visited,\n  sum(@code_verification_submitted_success) as\ncode_verification_submitted_success\n  by bin(1year)",
        "region": "${var.region}",
        "stacked": false,
        "title": "Letter flow funnel",
        "view": "bar"
      }
    }
  ]
}
  EOF
}
