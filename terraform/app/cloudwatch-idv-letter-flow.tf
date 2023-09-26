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
      "height": 6,
      "width": 24,
      "y": 0,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name in ['IdV: USPS address visited', 'IdV: USPS address letter requested', 'IdV: USPS address letter enqueued', 'IdV: GPO verification visited', 'IdV: GPO verification submitted']\n| fields (name = 'IdV: USPS address visited' and properties.new_event) as @letter_request_visited,\n  (name = 'IdV: USPS address letter requested' and\n!properties.event_properties.resend and properties.new_event) as @letter_request_submitted,\n  (name = 'IdV: USPS address letter enqueued' and\n!properties.event_properties.resend) as @letter_enqueued,\n  (name = 'IdV: GPO verification visited' and properties.new_event) as\n@code_verification_visited,\n  (name = 'IdV: GPO verification submitted' and\nproperties.event_properties.success and properties.new_event) as @code_verification_submitted_success\n| stats sum(@letter_request_visited) as letter_request_visited,\n  sum(@letter_request_submitted) as letter_request_submitted,\n  sum(@letter_enqueued) as letter_enqueued,\n  sum(@code_verification_visited) as code_verification_visited,\n  sum(@code_verification_submitted_success) as\ncode_verification_submitted_success\n  by bin(1year)",
        "region": "${var.region}",
        "stacked": false,
        "title": "Letter flow funnel",
        "view": "bar"
      }
    },
    {
      "height": 7,
      "width": 12,
      "y": 36,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name in ['IdV: USPS address letter requested', 'IdV: USPS address letter enqueued']\n| filter properties.new_event\n| filter properties.event_properties.resend = 0\n| fields (name = 'IdV: USPS address letter requested') as @requested\n| fields (name = 'IdV: USPS address letter enqueued') as @enqueued\n| stats sum(@requested) as requested, sum(@enqueued) as enqueued  by properties.event_properties.phone_step_attempts as attempts\n| sort attempts asc",
        "region": "${var.region}",
        "stacked": false,
        "view": "bar",
        "title": "Phone attempts before requesting/enqueueing letter (data since Aug 9, 2023)"
      }
    },
    {
      "height": 7,
      "width": 12,
      "y": 36,
      "x": 12,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name in ['IdV: USPS address letter requested', 'IdV: USPS address letter enqueued']\n| filter properties.new_event\n| filter properties.event_properties.resend = 0\n| fields (name = 'IdV: USPS address letter requested') as @requested\n| fields (@requested and properties.event_properties.phone_step_attempts = 0) as @zero_before_requested\n| fields (name = 'IdV: USPS address letter enqueued') as @enqueued\n| fields (@enqueued and properties.event_properties.phone_step_attempts = 0) as @zero_before_enqueued\n| stats sum(@zero_before_requested) as zero_before_requested,\n        sum(@requested) as requested, \n        sum(@zero_before_requested) / sum(@requested) * 100 as pct_requested,\n        sum(@zero_before_enqueued) as zero_before_enqueued,\n        sum(@enqueued) as enqueued, \n        sum(@zero_before_enqueued) / sum(@enqueued) * 100 as pct_enqueued",
        "region": "${var.region}",
        "stacked": false,
        "view": "table",
        "title": "Percentage of zero phone attempts before requesting letter (data since Aug 9, 2023)"
      }
    },
    {
      "height": 6,
      "width": 16,
      "y": 43,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, properties.event_properties.pending_profile_pending_reasons as reasons, @message\n| filter name in [\n    'Password Reset: Password Submitted'\n] and properties.event_properties.pending_profile_invalidated and properties.event_properties.pending_profile_pending_reasons like /gpo_verification_pending/\n| stats count(*)\nby bin(1day) as period\n| sort period asc",
        "region": "${var.region}",
        "stacked": false,
        "title": "Password resets while letter pending (data since July 28, 2023)",
        "view": "bar"
      }
    },
    {
      "height": 6,
      "width": 8,
      "y": 43,
      "x": 16,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, properties.event_properties.pending_profile_pending_reasons, @message\n| filter name in [\n    'Password Reset: Password Submitted'\n] and properties.event_properties.pending_profile_invalidated\n| stats count(properties.event_properties.pending_profile_pending_reasons) by properties.event_properties.pending_profile_pending_reasons\n",
        "region": "${var.region}",
        "stacked": false,
        "view": "table",
        "title": "Password reset pending reasons"
      }
    },
    {
      "height": 6,
      "width": 9,
      "y": 49,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name in [\n    'IdV: GPO verification submitted' ]\n| stats count(properties.event_properties.attempts) by properties.event_properties.attempts as count\n| sort count asc ",
        "region": "${var.region}",
        "stacked": false,
        "view": "bar",
        "title": "Num attempts to enter verification code (data since Aug 9, 2023)"
      }
    },
    {
      "height": 6,
      "width": 7,
      "y": 49,
      "x": 9,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name = 'IdV: GPO verification submitted' and properties.event_properties.success = 1 and properties.event_properties.letter_count > 1\n| stats count(*) by properties.event_properties.which_letter as which_letter\n| sort properties.event_properties.which_letter asc",
        "region": "${var.region}",
        "stacked": false,
        "title": "Which letter code, with multipe letters (data since Aug 9, 2023)",
        "view": "table"
      }
    },
    {
      "type": "log",
      "x": 16,
      "y": 49,
      "width": 8,
      "height": 6,
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name in ['IdV: USPS address letter requested', 'IdV: USPS address letter enqueued']\n| filter properties.new_event\n| filter properties.event_properties.resend = 1\n| fields (name = 'IdV: USPS address letter requested') as @requested\n| fields (name = 'IdV: USPS address letter enqueued') as @enqueued\n| stats sum(@requested) as requested, sum(@enqueued) as enqueued  by ceil(properties.event_properties.hours_since_first_letter/24) as days_since_first_letter\n| sort days_since_first_letter asc",
        "region": "${var.region}",
        "stacked": false,
        "title": "Days since first letter (data since Aug 18, 2023)",
        "view": "table"
      }
    }
  ]
}
  EOF
}
