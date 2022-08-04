resource "aws_cloudwatch_dashboard" "idv_funnel" {
  dashboard_name = "${var.env_name}-idv-funnel"

  dashboard_body = <<EOF
    {
  "start": "-PT72H",
  "widgets": [
    {
      "height": 6,
      "width": 24,
      "y": 0,
      "x": 0,
      "type": "text",
      "properties": {
        "markdown": "# Proofing funnel\n\nThe proofing funnel below shows the number of users that have viewed a given step. Specifically:\n\n- **Getting started** is the number of sessions that have seen the first step in the flow\n- **Document capture** is the number of sessions that have seen the screen to upload documents\n- **Document authentication** is the number of sessions that have uploaded images of a document\n- **Verify info** is the number of sessions that have made it to the SSN step\n- **Phone or address** is the number of sessions that have made it to the step for entering a phone number or opting for a letter\n- **Secure account** is the number of sessions that have made it to the password step\n- **Workflow complete** is the number of sessions that have completed the proofing workflow"
      }
    },
    {
      "height": 7,
      "width": 18,
      "y": 19,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name in [\n    'IdV: doc auth welcome visited',\n    'Frontend: IdV: front image clicked',\n    'IdV: doc auth image upload form submitted',\n    'IdV: personal key submitted'\n]\n| fields (name = 'IdV: doc auth welcome visited' and properties.new_event) as @proofing_started,\n         (name = 'Frontend: IdV: front image clicked' and properties.new_event)\nas @add_image_clicked,\n         (name = 'IdV: doc auth image upload form submitted' and\nproperties.event_properties.success and properties.new_event) as @document_capture_submitted,\n         (name = 'IdV: personal key submitted' and properties.new_event) as\n@personal_key_confirmed\n| stats sum(@personal_key_confirmed) / sum(@proofing_started) * 100 as blanket_success_rate,\n        sum(@personal_key_confirmed) /  sum(@document_capture_submitted) * 100\nas actual_success_rate by bin(1day)",
        "region": "${var.region}",
        "stacked": false,
        "title": "Proofing rate",
        "view": "timeSeries"
      }
    },
    {
      "height": 7,
      "width": 6,
      "y": 19,
      "x": 18,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name in [\n    'IdV: doc auth welcome visited',\n    'IdV: doc auth document_capture visited',\n    'Frontend: IdV: front image clicked',\n    'IdV: doc auth image upload form submitted',\n    'IdV: personal key submitted'\n]\n| fields (name = 'IdV: doc auth welcome visited' and properties.new_event) as @proofing_started,\n         (name = 'IdV: doc auth document_capture visited' and\nproperties.new_event) as @document_capture_visited,\n         (name = 'Frontend: IdV: front image clicked' and properties.new_event)\nas @add_image_clicked,\n         (name = 'IdV: doc auth image upload form submitted' and\nproperties.event_properties.success and properties.new_event) as @document_capture_submitted,\n         (name = 'IdV: personal key submitted' and properties.new_event) as\n@personal_key_confirmed\n| stats sum(@personal_key_confirmed) / sum(@proofing_started) * 100 as blanket_success_rate,\n        sum(@personal_key_confirmed) /  sum(@document_capture_submitted) * 100\nas actual_success_rate",
        "region": "${var.region}",
        "stacked": false,
        "title": "Proofing rate",
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
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name in [\n    'IdV: doc auth welcome visited',\n    'IdV: doc auth document_capture visited',\n    'IdV: doc auth image upload form submitted',\n    'IdV: doc auth ssn visited',\n    'IdV: phone of record visited',\n    'IdV: review info visited',\n    'IdV: personal key submitted'\n]\n| fields (name = 'IdV: doc auth welcome visited' and properties.new_event) as @getting_started,\n         (name = 'IdV: doc auth document_capture visited' and\nproperties.new_event) as @document_capture,\n         (name = 'IdV: doc auth image upload form submitted' and\nproperties.event_properties.success and properties.new_event) as @document_authentication,\n         (name = 'IdV: doc auth ssn visited' and properties.new_event) as\n@verify_info,\n         (name = 'IdV: phone of record visited' and properties.new_event) as\n@phone_or_address,\n         (name = 'IdV: review info visited' and properties.new_event) as\n@secure_account,\n         (name = 'IdV: personal key submitted' and properties.new_event) as\n@workflow_complete\n| stats sum(@getting_started) as getting_started,\n        sum(@document_capture) as document_capture,\n        sum(@document_authentication) as document_authentication,\n        sum(@verify_info) as verify_info,\n        sum(@phone_or_address) as phone_or_address,\n        sum(@secure_account) as secure_account,\n        sum(@workflow_complete) as workflow_complete\n        by bin(1year)",
        "region": "${var.region}",
        "stacked": false,
        "title": "Proofing funnel",
        "view": "bar"
      }
    },
    {
      "height": 9,
      "width": 24,
      "y": 30,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name in [ \n    'IdV: doc auth welcome visited', \n    'IdV: doc auth document_capture visited', \n    'IdV: doc auth image upload form submitted', \n    'IdV: doc auth ssn visited', \n    'IdV: phone of record visited', \n    'IdV: review info visited', \n    'IdV: personal key submitted' \n]\n| fields (name = 'IdV: doc auth welcome visited' and properties.new_event) as @getting_started, \n         (name = 'IdV: doc auth document_capture visited' and  properties.new_event) as @document_capture, \n         (name = 'IdV: doc auth image upload form submitted' and  properties.event_properties.success and properties.new_event) as @document_authentication, \n         (name = 'IdV: doc auth ssn visited' and properties.new_event) as @verify_info,\n         (name = 'IdV: phone of record visited' and properties.new_event) as @phone_or_address, \n         (name = 'IdV: review info visited' and properties.new_event) as @secure_account, \n         (name = 'IdV: personal key submitted' and properties.new_event) as @workflow_complete\n| stats (sum(@getting_started) - sum(@document_capture)) / sum(@getting_started) * 100 as getting_started,\n        (sum(@document_capture) - sum(@document_authentication)) / sum(@getting_started) * 100 as document_capture,\n        (sum(@document_authentication) - sum(@verify_info)) / sum(@getting_started) * 100 as document_authentication,\n        (sum(@verify_info) - sum(@phone_or_address)) / sum(@getting_started) * 100 as verify_info,\n        (sum(@phone_or_address) - sum(@secure_account)) / sum(@getting_started) * 100 as phone_or_address,\n        (sum(@secure_account) - sum(@workflow_complete)) / sum(@getting_started) * 100 as secure_account\n        # sum(@workflow_complete) / sum(@getting_started) * 100 as workflow_complete\n        by bin(1day)",
        "region": "${var.region}",
        "stacked": true,
        "title": "Net drop-off rates",
        "view": "timeSeries"
      }
    },
    {
      "height": 3,
      "width": 24,
      "y": 39,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name in [ \n    'IdV: doc auth welcome visited', \n    'IdV: doc auth document_capture visited', \n    'IdV: doc auth image upload form submitted', \n    'IdV: doc auth ssn visited', \n    'IdV: phone of record visited', \n    'IdV: review info visited', \n    'IdV: personal key submitted' \n]\n| fields (name = 'IdV: doc auth welcome visited' and properties.new_event) as @getting_started, \n         (name = 'IdV: doc auth document_capture visited' and  properties.new_event) as @document_capture, \n         (name = 'IdV: doc auth image upload form submitted' and  properties.event_properties.success and properties.new_event) as @document_authentication, \n         (name = 'IdV: doc auth ssn visited' and properties.new_event) as @verify_info,\n         (name = 'IdV: phone of record visited' and properties.new_event) as @phone_or_address, \n         (name = 'IdV: review info visited' and properties.new_event) as @secure_account, \n         (name = 'IdV: personal key submitted' and properties.new_event) as @workflow_complete\n| stats (sum(@getting_started) - sum(@document_capture)) / sum(@getting_started) * 100 as getting_started,\n        (sum(@document_capture) - sum(@document_authentication)) / sum(@getting_started) * 100 as document_capture,\n        (sum(@document_authentication) - sum(@verify_info)) / sum(@getting_started) * 100 as document_authentication,\n        (sum(@verify_info) - sum(@phone_or_address)) / sum(@getting_started) * 100 as verify_info,\n        (sum(@phone_or_address) - sum(@secure_account)) / sum(@getting_started) * 100 as phone_or_address,\n        (sum(@secure_account) - sum(@workflow_complete)) / sum(@getting_started) * 100 as secure_account,\n        sum(@workflow_complete) / sum(@getting_started) * 100 as workflow_complete\n        by bin(1year)",
        "region": "${var.region}",
        "stacked": false,
        "title": "Net drop-off rates",
        "view": "table"
      }
    },
    {
      "height": 4,
      "width": 24,
      "y": 15,
      "x": 0,
      "type": "text",
      "properties": {
        "markdown": "### Proofing rate\n\nThe funnel is used to compute proofing success rates. Success rates are broken into 2 categories:\n\n- **Blanket proofing success rate**: The percentage of sessions that complete the workflow from the getting started step\n- **Actual proofing success rate**: The percentage of sessions that complete the workflow after uploading a document for the document authentication step"
      }
    },
    {
      "height": 4,
      "width": 24,
      "y": 26,
      "x": 0,
      "type": "text",
      "properties": {
        "markdown": "### Drop-off rates\n\nDrop-off rates describe the percentage of sessions that do not make it to a succeeding step after visiting a given step.\n\n- **Net drop-off rates**: The percentage of sessions that drop off from a step from the total number that start the flow\n- **Per-step drop-off rates**: The percentage of sessions that drop off from a step from the sessions that completed the preceeding step."
      }
    },
    {
      "height": 9,
      "width": 24,
      "y": 42,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name in [ \n    'IdV: doc auth welcome visited', \n    'IdV: doc auth document_capture visited', \n    'IdV: doc auth image upload form submitted', \n    'IdV: doc auth ssn visited', \n    'IdV: phone of record visited', \n    'IdV: review info visited', \n    'IdV: personal key submitted' \n]\n| fields (name = 'IdV: doc auth welcome visited' and properties.new_event) as @getting_started, \n         (name = 'IdV: doc auth document_capture visited' and  properties.new_event) as @document_capture, \n         (name = 'IdV: doc auth image upload form submitted' and  properties.event_properties.success and properties.new_event) as @document_authentication, \n         (name = 'IdV: doc auth ssn visited' and properties.new_event) as @verify_info,\n         (name = 'IdV: phone of record visited' and properties.new_event) as @phone_or_address, \n         (name = 'IdV: review info visited' and properties.new_event) as @secure_account, \n         (name = 'IdV: personal key submitted' and properties.new_event) as @workflow_complete\n| stats (sum(@getting_started) - sum(@document_capture)) / sum(@getting_started) * 100 as getting_started,\n        (sum(@document_capture) - sum(@document_authentication)) / sum(@document_capture) * 100 as document_capture,\n        (sum(@document_authentication) - sum(@verify_info)) / sum(@document_authentication) * 100 as document_authentication,\n        (sum(@verify_info) - sum(@phone_or_address)) / sum(@verify_info) * 100 as verify_info,\n        (sum(@phone_or_address) - sum(@secure_account)) / sum(@phone_or_address) * 100 as phone_or_address,\n        (sum(@secure_account) - sum(@workflow_complete)) / sum(@secure_account) * 100 as secure_account\n        by bin(1day)",
        "region": "${var.region}",
        "stacked": false,
        "title": "Per-step drop-off rates",
        "view": "timeSeries"
      }
    },
    {
      "height": 3,
      "width": 24,
      "y": 51,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name in [ \n    'IdV: doc auth welcome visited', \n    'IdV: doc auth document_capture visited', \n    'IdV: doc auth image upload form submitted', \n    'IdV: doc auth ssn visited', \n    'IdV: phone of record visited', \n    'IdV: review info visited', \n    'IdV: personal key submitted' \n]\n| fields (name = 'IdV: doc auth welcome visited' and properties.new_event) as @getting_started, \n         (name = 'IdV: doc auth document_capture visited' and  properties.new_event) as @document_capture, \n         (name = 'IdV: doc auth image upload form submitted' and  properties.event_properties.success and properties.new_event) as @document_authentication, \n         (name = 'IdV: doc auth ssn visited' and properties.new_event) as @verify_info,\n         (name = 'IdV: phone of record visited' and properties.new_event) as @phone_or_address, \n         (name = 'IdV: review info visited' and properties.new_event) as @secure_account, \n         (name = 'IdV: personal key submitted' and properties.new_event) as @workflow_complete\n| stats (sum(@getting_started) - sum(@document_capture)) / sum(@getting_started) * 100 as getting_started,\n        (sum(@document_capture) - sum(@document_authentication)) / sum(@document_capture) * 100 as document_capture,\n        (sum(@document_authentication) - sum(@verify_info)) / sum(@document_authentication) * 100 as document_authentication,\n        (sum(@verify_info) - sum(@phone_or_address)) / sum(@verify_info) * 100 as verify_info,\n        (sum(@phone_or_address) - sum(@secure_account)) / sum(@phone_or_address) * 100 as phone_or_address,\n        (sum(@secure_account) - sum(@workflow_complete)) / sum(@secure_account) * 100 as secure_account\n        by bin(1year)",
        "region": "${var.region}",
        "stacked": false,
        "title": "Per-step drop-off rates",
        "view": "table"
      }
    },
    {
      "height": 3,
      "width": 24,
      "y": 12,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name in [\n    'IdV: doc auth welcome visited',\n    'IdV: doc auth document_capture visited',\n    'IdV: doc auth image upload form submitted',\n    'IdV: doc auth ssn visited',\n    'IdV: phone of record visited',\n    'IdV: review info visited',\n    'IdV: personal key submitted'\n]\n| fields (name = 'IdV: doc auth welcome visited' and properties.new_event) as @getting_started,\n         (name = 'IdV: doc auth document_capture visited' and\nproperties.new_event) as @document_capture,\n         (name = 'IdV: doc auth image upload form submitted' and\nproperties.event_properties.success and properties.new_event) as @document_authentication,\n         (name = 'IdV: doc auth ssn visited' and properties.new_event) as\n@verify_info,\n         (name = 'IdV: phone of record visited' and properties.new_event) as\n@phone_or_address,\n         (name = 'IdV: review info visited' and properties.new_event) as\n@secure_account,\n         (name = 'IdV: personal key submitted' and properties.new_event) as\n@workflow_complete\n| stats sum(@getting_started) as getting_started,\n        sum(@document_capture) as document_capture,\n        sum(@document_authentication) as document_authentication,\n        sum(@verify_info) as verify_info,\n        sum(@phone_or_address) as phone_or_address,\n        sum(@secure_account) as secure_account,\n        sum(@workflow_complete) as workflow_complete\n        by bin(1year)",
        "region": "${var.region}",
        "stacked": false,
        "title": "Proofing funnel",
        "view": "table"
      }
    }
  ]
}
  EOF
}
