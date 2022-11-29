resource "aws_cloudwatch_dashboard" "idv_inherited_proofing_funnel" {
  dashboard_name = "${var.env_name}-idv-inherited-proofing-funnel"

  dashboard_body = <<EOF
    {
        "start": "-PT72H",
        "widgets": [
            {
                "height": 9,
                "width": 24,
                "y": 0,
                "x": 0,
                "type": "text",
                "properties": {
                    "markdown": "# Proofing funnel - Inherited Proofing (IP)\n\nThe proofing funnel below shows the number of users that have viewed a given step. Specifically:\n\n- **start_visited** is the number of sessions that have seen the Getting Started step in the flow\n- **start_submitted** is the number of sessions that have successfully finished the Getting Started step\n- **agreement_visited** is the number of sessions that have seen the Agreement step in the flow\n- **agreement_submitted** is the number of sessions that have successfully finished the Agreement step\n- **api_visited** is the number of sessions that have successfully started the IP API call to service provider\n- **api_wait_visited** is the number of sessions that have seen the IP API call in the flow\n- **api_submitted** is the number of sessions that have successfully finished the IP API step\n\nNOTE: these are all of the inherited proofing analytics events that are available, to date."
                }
            },
            {
                "height": 6,
                "width": 24,
                "y": 9,
                "x": 0,
                "type": "log",
                "properties": {
                    "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name in [\n\n\n\n    'Idv: inherited proofing get started visited',\n\n\n\n    'Idv: inherited proofing get started submitted',\n\n\n\n    'Idv: inherited proofing agreement visited',\n\n\n\n    'Idv: inherited proofing agreement submitted',\n\n\n\n    'IdV: doc auth verify visited',\n\n\n\n    'IdV: doc auth verify_wait visited',\n\n\n\n    'IdV: doc auth optional verify_wait submitted'\n\n\n\n]\n| fields (name = 'Idv: inherited proofing get started visited' and properties.new_event) as @start_visited,\n\n\n\n         (name = 'Idv: inherited proofing get started submitted' and\n\nproperties.new_event) as @start_submitted,\n\n\n\n         (name = 'Idv: inherited proofing agreement visited' and\n\nproperties.new_event) as @agreement_visited,\n\n\n\n         (name = 'Idv: inherited proofing agreement submitted' and\n\nproperties.new_event) as @agreement_submitted,\n\n\n\n         (name = 'IdV: doc auth verify visited' and properties.new_event and\n\nproperties.event_properties.analytics_id = 'Inherited Proofing') as @api_visited,\n\n\n\n         (name = 'IdV: doc auth verify_wait visited' and properties.new_event\n\nand properties.event_properties.analytics_id = 'Inherited Proofing') as @api_wait_visited,\n\n\n\n         (name = 'IdV: doc auth optional verify_wait submitted' and\n\nproperties.new_event and properties.event_properties.analytics_id = 'Inherited Proofing') as @api_submitted\n| stats sum(@start_visited) as start_visited,\n\n\n\n        sum(@start_submitted) as start_submitted,\n\n\n\n        sum(@agreement_visited) as agreement_visited,\n\n\n\n        sum(@agreement_submitted) as agreement_submitted,\n\n\n\n        sum(@api_visited) as api_visited,\n\n\n\n        sum(@api_wait_visited) as api_wait_visited,\n\n\n\n        sum(@api_submitted) as api_submitted\n\n\n\n        by bin(1year)",
                    "region": "${var.region}",
                    "stacked": false,
                    "title": "Log group: ${var.env_name}_/srv/idp/shared/log/events.log",
                    "view": "bar"
                }
            },
            {
                "height": 6,
                "width": 24,
                "y": 15,
                "x": 0,
                "type": "log",
                "properties": {
                    "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name in [\n\n\n\n    'Idv: inherited proofing get started visited',\n\n\n\n    'Idv: inherited proofing get started submitted',\n\n\n\n    'Idv: inherited proofing agreement visited',\n\n\n\n    'Idv: inherited proofing agreement submitted',\n\n\n\n    'IdV: doc auth verify visited',\n\n\n\n    'IdV: doc auth verify_wait visited',\n\n\n\n    'IdV: doc auth optional verify_wait submitted'\n\n\n\n]\n| fields (name = 'Idv: inherited proofing get started visited' and properties.new_event) as @start_visited,\n\n\n\n         (name = 'Idv: inherited proofing get started submitted' and\n\nproperties.new_event) as @start_submitted,\n\n\n\n         (name = 'Idv: inherited proofing agreement visited' and\n\nproperties.new_event) as @agreement_visited,\n\n\n\n         (name = 'Idv: inherited proofing agreement submitted' and\n\nproperties.new_event) as @agreement_submitted,\n\n\n\n         (name = 'IdV: doc auth verify visited' and properties.new_event and\n\nproperties.event_properties.analytics_id = 'Inherited Proofing') as @api_visited,\n\n\n\n         (name = 'IdV: doc auth verify_wait visited' and properties.new_event\n\nand properties.event_properties.analytics_id = 'Inherited Proofing') as @api_wait_visited,\n\n\n\n         (name = 'IdV: doc auth optional verify_wait submitted' and\n\nproperties.new_event and properties.event_properties.analytics_id = 'Inherited Proofing') as @api_submitted| stats sum(@start_visited) as start_visited,\n\n\n\n        sum(@start_submitted) as start_submitted,\n\n\n\n        sum(@agreement_visited) as agreement_visited,\n\n\n\n        sum(@agreement_submitted) as agreement_submitted,\n\n\n\n        sum(@api_visited) as api_visited,\n\n\n\n        sum(@api_wait_visited) as api_wait_visited,\n\n\n\n        sum(@api_submitted) as api_submitted\n\n\n\n        by bin(1year)\n",
                    "region": "${var.region}",
                    "stacked": false,
                    "title": "Log group: ${var.env_name}_/srv/idp/shared/log/events.log",
                    "view": "table"
                }
            },
            {
                "height": 6,
                "width": 24,
                "y": 21,
                "x": 0,
                "type": "log",
                "properties": {
                    "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | # 221115 jscodefix add IdV cancellation events, filter by Inherited Proofing\n# 221109 jscodefix enhanced with the doc auth (inherited proofing API calls)\nfields @timestamp, @message\n| filter name in [\n\n\n\n\n\n\n\n    'IdV: inherited proofing get_started visited',\n\n\n\n\n\n\n\n    'IdV: inherited proofing get_started submitted',\n\n\n\n\n\n\n\n    'IdV: inherited proofing agreement visited',\n\n\n\n\n\n\n\n    'IdV: inherited proofing agreement submitted',\n\n\n\n\n\n\n\n    'IdV: doc auth verify visited',\n\n\n\n\n\n\n\n    'IdV: doc auth verify_wait visited',\n\n\n\n\n\n\n\n    'IdV: doc auth optional verify_wait submitted',\n\n\n\n\n\n\n\n    'IdV: cancellation visited',\n\n\n\n\n\n\n\n    'IdV: cancellation go back',\n\n\n\n\n\n\n\n    'IdV: cancellation confirmed'\n\n\n\n\n\n\n\n]\n| fields (name = 'IdV: inherited proofing get started visited' and properties.new_event) as @get_started_visited,\n\n\n\n\n\n\n\n         (name = 'IdV: inherited proofing get started submitted' and\n\n\n\nproperties.new_event) as @get_started_submitted,\n\n\n\n\n\n\n\n         (name = 'IdV: inherited proofing agreement visited' and\n\n\n\nproperties.new_event) as @agreement_visited,\n\n\n\n\n\n\n\n         (name = 'IdV: inherited proofing agreement submitted' and\n\n\n\nproperties.new_event) as @agreement_submitted,\n\n\n\n\n\n\n\n         (name = 'IdV: doc auth verify visited' and properties.new_event and\n\n\n\nproperties.event_properties.analytics_id = 'Inherited Proofing') as @api_visited,\n\n\n\n\n\n\n\n         (name = 'IdV: doc auth verify_wait visited' and properties.new_event\n\n\n\nand properties.event_properties.analytics_id = 'Inherited Proofing') as @api_wait_visited,\n\n\n\n\n\n\n\n         (name = 'IdV: doc auth optional verify_wait submitted' and\n\n\n\nproperties.new_event and properties.event_properties.analytics_id = 'Inherited Proofing') as @api_submitted,\n\n\n\n\n\n\n\n         (name = 'IdV: cancellation visited') as @cancel_visited,\n\n\n\n\n\n\n\n         (name = 'IdV: cancellation go back') as @cancel_go_back,\n\n\n\n\n\n\n\n         (name = 'IdV: cancellation confirmed') as @cancel_confirmed\n\n\n\n| stats sum(@get_started_visited) as get_started_visited,\n\n\n\n\n\n\n\n        sum(@get_started_submitted) as get_started_submitted,\n\n\n\n\n\n\n\n        sum(@agreement_visited) as agreement_visited,\n\n\n\n\n\n\n\n        sum(@agreement_submitted) as agreement_submitted,\n\n\n\n\n\n\n\n        sum(@api_visited) as api_visited,\n\n\n\n\n\n\n\n        sum(@api_wait_visited) as api_wait_visited,\n\n\n\n\n\n\n\n        sum(@api_submitted) as api_submitted,\n\n\n\n\n\n\n\n        sum(@cancel_visited) as cancel_visited,\n\n\n\n\n\n\n\n        sum(@cancel_go_back) as cancel_go_back,\n\n\n\n\n\n\n\n        sum(@cancel_confirmed) as cancel_confirmed\n\n\n\n\n\n\n\n        by bin(1year)\n",
                    "region": "${var.region}",
                    "stacked": false,
                    "title": "all events - Integration (v0.3)",
                    "view": "bar"
                }
            },
            {
                "height": 6,
                "width": 24,
                "y": 27,
                "x": 0,
                "type": "log",
                "properties": {
                    "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | # 221115 jscodefix add IdV cancellation events, filter by Inherited Proofing\n# 221109 jscodefix enhanced with the doc auth (inherited proofing API calls)\nfields @timestamp, @message\n| filter name in [\n\n\n\n\n\n\n\n    'IdV: inherited proofing get_started visited',\n\n\n\n\n\n\n\n    'IdV: inherited proofing get_started submitted',\n\n\n\n\n\n\n\n    'IdV: inherited proofing agreement visited',\n\n\n\n\n\n\n\n    'IdV: inherited proofing agreement submitted',\n\n\n\n\n\n\n\n    'IdV: doc auth verify visited',\n\n\n\n\n\n\n\n    'IdV: doc auth verify_wait visited',\n\n\n\n\n\n\n\n    'IdV: doc auth optional verify_wait submitted',\n\n\n\n\n\n\n\n    'IdV: cancellation visited',\n\n\n\n\n\n\n\n    'IdV: cancellation go back',\n\n\n\n\n\n\n\n    'IdV: cancellation confirmed'\n\n\n\n\n\n\n\n]\n| fields (name = 'IdV: inherited proofing get started visited' and properties.new_event) as @get_started_visited,\n\n\n\n\n\n\n\n         (name = 'IdV: inherited proofing get started submitted' and\n\n\n\nproperties.new_event) as @get_started_submitted,\n\n\n\n\n\n\n\n         (name = 'IdV: inherited proofing agreement visited' and\n\n\n\nproperties.new_event) as @agreement_visited,\n\n\n\n\n\n\n\n         (name = 'IdV: inherited proofing agreement submitted' and\n\n\n\nproperties.new_event) as @agreement_submitted,\n\n\n\n\n\n\n\n         (name = 'IdV: doc auth verify visited' and properties.new_event and\n\n\n\nproperties.event_properties.analytics_id = 'Inherited Proofing') as @api_visited,\n\n\n\n\n\n\n\n         (name = 'IdV: doc auth verify_wait visited' and properties.new_event\n\n\n\nand properties.event_properties.analytics_id = 'Inherited Proofing') as @api_wait_visited,\n\n\n\n\n\n\n\n         (name = 'IdV: doc auth optional verify_wait submitted' and\n\n\n\nproperties.new_event and properties.event_properties.analytics_id = 'Inherited Proofing') as @api_submitted,\n\n\n\n\n\n\n\n         (name = 'IdV: cancellation visited' and\nproperties.event_properties.analytics_id = 'Inherited Proofing') as @cancel_visited,\n\n\n\n\n\n\n\n         (name = 'IdV: cancellation go back' and\nproperties.event_properties.analytics_id = 'Inherited Proofing') as @cancel_go_back,\n\n\n\n\n\n\n\n         (name = 'IdV: cancellation confirmed' and\nproperties.event_properties.analytics_id = 'Inherited Proofing') as @cancel_confirmed\n\n\n| stats sum(@get_started_visited) as get_started_visited,\n\n\n\n\n\n\n\n        sum(@get_started_submitted) as get_started_submitted,\n\n\n\n\n\n\n\n        sum(@agreement_visited) as agreement_visited,\n\n\n\n\n\n\n\n        sum(@agreement_submitted) as agreement_submitted,\n\n\n\n\n\n\n\n        sum(@api_visited) as api_visited,\n\n\n\n\n\n\n\n        sum(@api_wait_visited) as api_wait_visited,\n\n\n\n\n\n\n\n        sum(@api_submitted) as api_submitted,\n\n\n\n\n\n\n\n        sum(@cancel_visited) as cancel_visited,\n\n\n\n\n\n\n\n        sum(@cancel_go_back) as cancel_go_back,\n\n\n\n\n\n\n\n        sum(@cancel_confirmed) as cancel_confirmed\n\n\n\n\n\n\n\n        by bin(1year)\n",
                    "region": "${var.region}",
                    "stacked": false,
                    "title": "Log group: ${var.env_name}_/srv/idp/shared/log/events.log",
                    "view": "table"
                }
            }
        ]
    }
    EOF
}