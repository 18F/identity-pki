resource "aws_cloudwatch_dashboard" "attempts_events_backgound_job" {
  dashboard_name = "${var.env_name}-attempts-events-backgound-job"

  dashboard_body = <<EOF
    {
  "widgets": [
    {
      "height": 6,
      "width": 24,
      "y": 0,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/workers.log' | fields @timestamp, @message, name\n| filter name=\"IRSAttemptsEventJob\"\n| display name, start_time, end_time, duration_ms, events_count, file_bytes_size, file_bytes_size/1000 as file_size_in_kb\n| sort @timestamp desc\n",
        "region": "${var.region}",
        "stacked": false,
        "title": "Overview",
        "view": "table"
      }
    },
    {
      "height": 6,
      "width": 24,
      "y": 24,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/workers.log' | fields @timestamp, @message, job_class, exception_class_warn\n| filter job_class = \"IrsAttemptsEventsBatchJob\"\n| filter ispresent(exception_class_warn) or ispresent(exception_class)\n# | filter ispresent(enqueued_at)\n| sort @timestamp desc\n| display job_class, enqueued_at, queued_duration_ms, exception_class_warn, exception_class\n",
        "region": "${var.region}",
        "stacked": false,
        "title": "Any exception or warnings",
        "view": "table"
      }
    },
    {
      "height": 6,
      "width": 24,
      "y": 6,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/workers.log' | fields @timestamp, @message, name\n| filter name = \"IRSAttemptsEventJob\"\n| sort @timestamp asc\n| stats avg(duration_ms) by bin(1h)",
        "region": "${var.region}",
        "stacked": false,
        "title": "duration_ms per hour",
        "view": "bar"
      }
    },
    {
      "height": 6,
      "width": 24,
      "y": 12,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/workers.log' | fields @timestamp, @message, name\n| filter name = \"IRSAttemptsEventJob\"\n| sort @timestamp asc\n| stats avg(events_count) by bin(1h)",
        "region": "${var.region}",
        "stacked": false,
        "view": "bar",
        "title": "events count per hour"
      }
    },
    {
      "height": 6,
      "width": 24,
      "y": 18,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/workers.log' | fields @timestamp, @message, name\n| filter name = \"IRSAttemptsEventJob\"\n| sort @timestamp asc\n| stats avg(file_bytes_size) by bin(1h)",
        "region": "${var.region}",
        "stacked": false,
        "view": "bar",
        "title": "file size per hour (in bytes)"
      }
    }
  ]
}
  EOF
}
