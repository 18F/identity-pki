resource "aws_cloudwatch_dashboard" "idv_hybrid_handoff" {
  dashboard_name = "${var.env_name}-idv-hybrid-handoff"

  dashboard_body = <<EOF
    {
  "start": "-PT72H",
  "widgets": [
    {
      "height": 6,
      "width": 12,
      "y": 3,
      "x": 12,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = \"IdV: doc auth upload submitted\" and !properties.event_properties.skip_upload_step\n| fields properties.event_properties.destination as destination\n| fields destination = \"link_sent\" as link, destination = \"document_capture\" as desktop\n| stats sum(link) as switched_to_mobile, sum(desktop) as stayed_on_desktop by bin(1hour)",
        "region": "${var.region}",
        "stacked": true,
        "title": "Absolute number of users",
        "view": "timeSeries"
      }
    },
    {
      "height": 3,
      "width": 12,
      "y": 0,
      "x": 12,
      "type": "text",
      "properties": {
        "markdown": "# Hybrid vs Desktop selection\nAmong those who completed the hybrid handoff screen, two graphs showing the number of users who switched to a mobile device, thus joining the hybrid workflow, and those who stayed with desktop workflow."
      }
    },
    {
      "height": 6,
      "width": 12,
      "y": 9,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = \"IdV: doc auth upload submitted\"\n| fields properties.event_properties.skip_upload_step as skip\n| stats avg(!skip)*100 as did_hybrid_handoff by bin(1hour)\n",
        "region": "${var.region}",
        "stacked": true,
        "title": "Percentage who completed handoff",
        "view": "timeSeries"
      }
    },
    {
      "height": 3,
      "width": 12,
      "y": 0,
      "x": 0,
      "type": "text",
      "properties": {
        "markdown": "# Who completed handoff?\nTwo graphs showing the users who saw and completed the \"hybrid handoff\" screen (desktop users) and those who never saw the screen (mobile users). Users who saw but didn't complete the screen are not included."
      }
    },
    {
      "height": 6,
      "width": 24,
      "y": 29,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = \"IdV: doc auth image upload vendor submitted\" and properties.new_event\n| fields properties.event_properties.flow_path = 'standard' and !properties.browser_mobile as is_desktop\n| fields properties.event_properties.flow_path = 'hybrid' as is_hybrid\n| fields properties.browser_mobile as is_mobile\n| fields is_desktop and properties.event_properties.success as desktop_success\n| fields is_hybrid and properties.event_properties.success as hybrid_success\n| fields is_mobile and properties.event_properties.success as mobile_success\n| stats\n(sum(desktop_success)/sum(is_desktop))*100 as desktop,\n(sum(hybrid_success)/sum(is_hybrid))*100 as hybrid,\n(sum(mobile_success)/sum(is_mobile))*100 as mobile by bin(1h)\n",
        "region": "${var.region}",
        "stacked": false,
        "title": "Success rate of users who submit documents (successful doc auth submissions / total submissions)",
        "view": "timeSeries"
      }
    },
    {
      "height": 2,
      "width": 24,
      "y": 15,
      "x": 0,
      "type": "text",
      "properties": {
        "markdown": "# Document upload behaviour\nMetrics of how successful people were at adding images of their identifying documents via our vendors"
      }
    },
    {
      "height": 6,
      "width": 24,
      "y": 35,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = \"IdV: doc auth image upload vendor submitted\" and properties.new_event = 1\n| fields properties.event_properties.attempts as att \n| stats avg(att) as num_upload_attempts by bin(1h)",
        "region": "${var.region}",
        "stacked": false,
        "title": "Average number of upload attempts",
        "view": "timeSeries"
      }
    },
    {
      "height": 6,
      "width": 24,
      "y": 43,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name in [\"IdV: doc auth document_capture visited\", \"Frontend: IdV: Link sent capture doc polling started\"] and !properties.browser_bot and properties.new_event\n| fields @timestamp, name, properties.browser_platform_name as platform,\nproperties.browser_name as browser, properties.event_properties.flow_path as path\n| stats\nsum(name = \"Frontend: IdV: Link sent capture doc polling started\") as hybrid_links_sent,\nsum(path = \"hybrid\" and name = \"IdV: doc auth document_capture visited\") as hybrid_links_clicked\nby bin(1hr)\n",
        "region": "${var.region}",
        "stacked": false,
        "title": "Number of hybrid links we send and number that get clicked on (clicks are higher than sends for unknown reasons)",
        "view": "timeSeries"
      }
    },
    {
      "height": 2,
      "width": 24,
      "y": 41,
      "x": 0,
      "type": "text",
      "properties": {
        "markdown": "# Hybrid link behaviour\nNumber people who get a hybrid link texted to them, and the number who open it"
      }
    },
    {
      "height": 6,
      "width": 12,
      "y": 3,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = \"IdV: doc auth upload submitted\"\n| fields properties.event_properties.skip_upload_step as skip_upload_step\n| stats sum(!skip_upload_step) as hybrid_step_submitted, sum(skip_upload_step) as hybrid_step_skipped by bin(1hour)\n",
        "region": "${var.region}",
        "stacked": true,
        "title": "Absolute number of users",
        "view": "timeSeries"
      }
    },
    {
      "height": 6,
      "width": 12,
      "y": 9,
      "x": 12,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = \"IdV: doc auth upload submitted\" and !properties.event_properties.skip_upload_step\n| fields properties.event_properties.destination as destination\n| fields destination = \"link_sent\" as mobile\n| stats avg(mobile)*100 as switched_to_mobile by bin(1hour)\n",
        "region": "${var.region}",
        "stacked": true,
        "title": "Percentage who chose mobile at the hybrid handoff screen",
        "view": "timeSeries"
      }
    },
    {
      "height": 6,
      "width": 24,
      "y": 17,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name in [\"IdV: doc auth document_capture visited\", \"Frontend: IdV: front image added\"] and properties.new_event\n# records of starting doc capture\n| fields properties.event_properties.flow_path = 'standard' and name = \"IdV: doc auth document_capture visited\" and !properties.browser_mobile as started_desktop\n| fields properties.event_properties.flow_path = 'hybrid' and name = \"IdV: doc auth document_capture visited\" as started_hybrid\n| fields properties.browser_mobile and name = \"IdV: doc auth document_capture visited\" as started_mobile\n# records of finishing the capture\n| fields properties.event_properties.flow_path = 'standard' and name = \"Frontend: IdV: front image added\" and !properties.browser_mobile as added_desktop\n| fields properties.event_properties.flow_path = 'hybrid' and name = \"Frontend: IdV: front image added\" as added_hybrid\n| fields properties.browser_mobile and name = \"Frontend: IdV: front image added\" as added_mobile\n# convert to percentages\n| stats\n(sum(added_desktop)/sum(started_desktop))*100 as desktop,\n(sum(added_hybrid)/sum(started_hybrid))*100 as hybrid,\n(sum(added_mobile)/sum(started_mobile))*100 as mobile by bin(1h)\n",
        "region": "${var.region}",
        "stacked": false,
        "title": "Rate of front image upload (front image uploads / number of visits)",
        "view": "timeSeries"
      }
    },
    {
      "height": 6,
      "width": 24,
      "y": 23,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter (name = \"IdV: doc auth image upload vendor submitted\" and properties.new_event and properties.event_properties.success) or (name = 'IdV: doc auth document_capture visited' and properties.new_event)\n| fields properties.event_properties.flow_path = 'standard' and !properties.browser_mobile as is_desktop\n| fields properties.event_properties.flow_path = 'hybrid' as is_hybrid\n| fields properties.browser_mobile as is_mobile\n| fields name = 'IdV: doc auth document_capture visited' as visited, name = \"IdV: doc auth image upload vendor submitted\" as success\n| fields is_desktop and success as desktop_success, is_desktop and visited as desktop_visited\n| fields is_hybrid and success as hybrid_success, is_hybrid and visited as hybrid_visited\n| fields is_mobile and success as mobile_success, is_mobile and visited as mobile_visited\n| stats\n(sum(desktop_success)/sum(desktop_visited))*100 as desktop,\n(sum(hybrid_success)/sum(hybrid_visited))*100 as hybrid,\n(sum(mobile_success)/sum(mobile_visited))*100 as mobile by bin(1h)\n",
        "region": "${var.region}",
        "stacked": false,
        "title": "Success rate of users who reach document capture (successful doc auth submissions / number of visits)",
        "view": "timeSeries"
      }
    }
  ]
}
  EOF
}
