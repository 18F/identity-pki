resource "aws_cloudwatch_dashboard" "idv_mva_timeouts" {
  dashboard_name = "${var.env_name}-idv-mva-timeouts"

  dashboard_body = <<EOF
    {
  "start": "-PT72H",
  "widgets": [
    {
      "height": 9,
      "width": 19,
      "y": 0,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth optional verify_wait submitted' and properties.event_properties.proofing_results.context.stages.state_id.vendor_name = 'aamva:state_id' and ispresent(properties.event_properties.proofing_results.context.stages.state_id.exception)\n| stats count(*) as error_count by bin(6hr)",
        "region": "${var.region}",
        "stacked": false,
        "title": "AAMVA Error Volumes",
        "view": "timeSeries"
      }
    },
    {
      "height": 12,
      "width": 24,
      "y": 28,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth optional verify_wait submitted' and properties.event_properties.proofing_results.context.stages.state_id.vendor_name = 'aamva:state_id' and ispresent(properties.event_properties.proofing_results.context.stages.state_id.exception)\n| parse properties.event_properties.proofing_results.context.stages.state_id.exception /ExceptionText: (?<exception_text>[^\\,]+),/\n| parse properties.event_properties.proofing_results.context.stages.state_id.exception /AAMVA raised (?<exception_name>[^ ]+)/\n| fields coalesce(exception_text, exception_name, 'unknown') as @exception\n| stats count(*) as error_count by @exception as exception_type\n| sort error_count desc",
        "region": "${var.region}",
        "stacked": false,
        "view": "bar",
        "title": "Types of AAMVA errors"
      }
    },
    {
      "height": 9,
      "width": 5,
      "y": 0,
      "x": 19,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth optional verify_wait submitted' and properties.event_properties.proofing_results.context.stages.state_id.vendor_name = 'aamva:state_id' and ispresent(properties.event_properties.proofing_results.context.stages.state_id.exception)\n| stats count(*) as error_count",
        "region": "${var.region}",
        "stacked": false,
        "title": "AAMVA Error Volumes",
        "view": "table"
      }
    },
    {
      "height": 9,
      "width": 19,
      "y": 9,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth optional verify_wait submitted' and properties.event_properties.proofing_results.context.stages.state_id.vendor_name = 'aamva:state_id'\n| fields ispresent(properties.event_properties.proofing_results.context.stages.state_id.exception) as @exception\n| stats sum(@exception) / count(*) * 100 as error_rate by bin(6hr)",
        "region": "${var.region}",
        "stacked": false,
        "title": "AAMVA Error Rate",
        "view": "timeSeries"
      }
    },
    {
      "height": 9,
      "width": 5,
      "y": 9,
      "x": 19,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth optional verify_wait submitted' and properties.event_properties.proofing_results.context.stages.state_id.vendor_name = 'aamva:state_id'\n| fields ispresent(properties.event_properties.proofing_results.context.stages.state_id.exception) as @exception\n| stats sum(@exception) / count(*) * 100 as error_rate",
        "region": "${var.region}",
        "stacked": false,
        "title": "AAMVA Error Rate",
        "view": "table"
      }
    },
    {
      "height": 10,
      "width": 24,
      "y": 18,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth optional verify_wait submitted' and properties.event_properties.proofing_results.context.stages.state_id.vendor_name = 'aamva:state_id'\n| fields ispresent(properties.event_properties.proofing_results.context.stages.state_id.exception) as @exception, properties.event_properties.proofing_results.context.stages.state_id.success as @success, !properties.event_properties.proofing_results.context.stages.state_id.success as @failure\n| stats sum(@success) as successful_transactions, sum(@success) / count(*) * 100 as success_rate, sum(@exception) as exception_transactions, count(*) as total_transacions, sum(@exception) / count(*) * 100 as error_rate, (sum(@failure) - sum(@exception)) / count(*) * 100 as failure_rate by properties.event_properties.proofing_results.context.stages.state_id.state_id_jurisdiction as state\n| display total_transacions, state, successful_transactions, exception_transactions, success_rate, failure_rate, error_rate\n| sort success_rate asc\n",
        "region": "${var.region}",
        "stacked": false,
        "title": "AAMVA Rates By State",
        "view": "table"
      }
    }
  ]
}
  EOF
}
