resource "aws_cloudwatch_dashboard" "idv_document_capture" {
  dashboard_name = "${var.env_name}-idv-document-capture"

  dashboard_body = <<EOF
    {
  "widgets": [
    {
      "height": 6,
      "width": 20,
      "y": 27,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth image upload vendor submitted'\n| fields @timestamp, @message, properties.event_properties.success as @success, !properties.event_properties.success as @failure\n| stats sum(@success) as successful_transactions, sum(@failure) as failed_transactions by bin(10min)\n| sort @timestamp desc",
        "region": "${var.region}",
        "stacked": true,
        "title": "Document submission volume",
        "view": "timeSeries"
      }
    },
    {
      "height": 5,
      "width": 20,
      "y": 17,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth document_capture visited' or (name = 'IdV: doc auth image upload vendor submitted' and properties.event_properties.success)\n| fields name = 'IdV: doc auth document_capture visited' as @visited, name = 'IdV: doc auth image upload vendor submitted' as @success\n| filter properties.new_event\n| stats sum(@success) / sum(@visited) * 100 as success_rate by bin(1hour)\n| sort @timestamp desc",
        "region": "${var.region}",
        "stacked": false,
        "title": "Document capture step success rate - How many sessions which reached this step ultimately passed this step?",
        "view": "timeSeries"
      }
    },
    {
      "height": 6,
      "width": 24,
      "y": 5,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp,\n  @message,\n  (name == 'IdV: doc auth document_capture visited' and properties.new_event)\nas @document_capture_visited,\n  (name == 'Frontend: IdV: Acuant SDK loaded' and properties.new_event) as\n@acuant_sdk_loaded,\n  (name == 'Frontend: IdV: front image clicked' and properties.new_event) as\n@front_image_clicked,\n  (name = 'Frontend: IdV: front image added' and properties.new_event) as\n@front_image_added,\n  (name = 'Frontend: IdV: back image clicked' and properties.new_event) as\n@back_image_clicked,\n  (name = 'Frontend: IdV: back image added' and properties.new_event) as\n@back_image_added,\n  (name = 'IdV: doc auth image upload form submitted' and properties.new_event)\nas @image_form_submitted,\n  (name = 'IdV: doc auth image upload vendor submitted' and\nproperties.event_properties.success and  properties.new_session_success_state) as @images_vendor_submitted_success\n| stats sum(@document_capture_visited) as document_capture_visited,\n  sum(@acuant_sdk_loaded) as acuant_sdk_loaded,\n  sum(@front_image_clicked) as front_image_clicked,\n  sum(@front_image_added) as front_image_added,\n  sum(@back_image_clicked) as back_image_clicked,\n  sum(@back_image_added) as back_image_added,\n  sum(@image_form_submitted) as image_form_submitted,\n  sum(@images_vendor_submitted_success) as images_vendor_submitted_success\n  by bin(1year)",
        "region": "${var.region}",
        "stacked": false,
        "title": "Document capture flow funnel",
        "view": "bar"
      }
    },
    {
      "height": 5,
      "width": 4,
      "y": 17,
      "x": 20,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth document_capture visited' or (name = 'IdV: doc auth image upload vendor submitted' and properties.event_properties.success)\n| fields name = 'IdV: doc auth document_capture visited' as @visited, name = 'IdV: doc auth image upload vendor submitted' as @success\n| filter properties.new_event\n| stats sum(@success) / sum(@visited) * 100 as success_rate",
        "region": "${var.region}",
        "stacked": false,
        "title": "Document capture step success rate",
        "view": "table"
      }
    },
    {
      "height": 6,
      "width": 20,
      "y": 79,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth image upload vendor submitted'\n| filter ispresent(properties.event_properties.doc_auth_result)\n| fields @timestamp, @message,\n  properties.event_properties.doc_auth_result = 'Passed' as @passed,\n  properties.event_properties.doc_auth_result = 'Attention' as\n@attention,\n  properties.event_properties.doc_auth_result = 'Failed' as @failed,\n  properties.event_properties.doc_auth_result = 'Unknown' as @unknown\n| stats sum(@passed) / count() * 100 as passed,\n  sum(@attention) / count() * 100 as attention,\n  sum(@failed) / count() * 100 as failed,\n  sum(@unknown) / count() * 100 as unknown\n  by bin(1hr)\n| sort @timestamp desc",
        "region": "${var.region}",
        "stacked": true,
        "title": "Document submission result",
        "view": "timeSeries"
      }
    },
    {
      "height": 6,
      "width": 4,
      "y": 79,
      "x": 20,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth image upload vendor submitted'\n| filter ispresent(properties.event_properties.doc_auth_result)\n| stats count() as result_count by properties.event_properties.doc_auth_result as status\n| sort result_count desc",
        "region": "${var.region}",
        "stacked": false,
        "title": "Document submission result",
        "view": "table"
      }
    },
    {
      "height": 6,
      "width": 4,
      "y": 27,
      "x": 20,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth image upload vendor submitted'\n| fields @timestamp, @message, properties.event_properties.success as @success, !properties.event_properties.success as @failure\n| stats sum(@success) as successful_transactions, sum(@failure) as failed_transactions\n",
        "region": "${var.region}",
        "stacked": true,
        "title": "Document submission volume",
        "view": "table"
      }
    },
    {
      "height": 3,
      "width": 24,
      "y": 43,
      "x": 0,
      "type": "text",
      "properties": {
        "markdown": "# Mobile platform stats:\n\nThese statistics describe document capture performance by mobile platform. These include the success rate and the number of transactions.\n\nMost of these graphs are broken out by upload method: either using the Acuant SDK or uploading directly using the built-in file picker.\n\nSuccess rate as described in these charts is the percentage of submissions amongst the total submissions."
      }
    },
    {
      "height": 7,
      "width": 24,
      "y": 46,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth image upload vendor submitted'\n| filter properties.browser_mobile\n| parse properties.browser_platform_version /(?<major_version>^[^\\.]+)/\n| fields (name = 'IdV: doc auth image upload vendor submitted' and properties.event_properties.client_image_metrics.back.source = 'upload') as @upload_submit,\n  (name = 'IdV: doc auth image upload vendor submitted' and properties.event_properties.client_image_metrics.back.source = 'upload' and properties.event_properties.success) as @upload_success,\n  (name = 'IdV: doc auth image upload vendor submitted' and properties.event_properties.client_image_metrics.back.source = 'acuant') as @acuant_submit,\n  (name = 'IdV: doc auth image upload vendor submitted' and properties.event_properties.client_image_metrics.back.source = 'acuant' and properties.event_properties.success) as @acuant_success\n| fields concat(properties.browser_platform_name, ' ', major_version) as platform\n| stats sum(@acuant_success) / sum(@acuant_submit) * 100 as acuant_success_rate, sum(@upload_success) / sum(@upload_submit) * 100 as upload_success_rate, count() as volume by platform\n| display platform, acuant_success_rate, upload_success_rate\n| sort volume desc\n| limit 6",
        "region": "${var.region}",
        "stacked": false,
        "title": "Success rate by upload method by mobile platform",
        "view": "bar"
      }
    },
    {
      "height": 7,
      "width": 24,
      "y": 53,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth image upload vendor submitted'\n| filter properties.browser_mobile\n| parse properties.browser_platform_version /(?<major_version>^[^\\.]+)/\n| fields properties.event_properties.success as @success,\n  !properties.event_properties.success as @failure\n| fields concat(properties.browser_platform_name, ' ', major_version) as platform\n| stats sum(@success) as successful_transactions, sum(@failure) as failed_transactions, count() as volume by platform\n| display platform, successful_transactions, failed_transactions\n| sort volume desc\n| limit 6",
        "region": "${var.region}",
        "stacked": false,
        "title": "Volume of successful and failed transactions by mobile platform",
        "view": "bar"
      }
    },
    {
      "height": 8,
      "width": 14,
      "y": 62,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @message\n| filter name = 'Frontend: IdV: Image capture failed'\n| filter properties.browser_mobile\n| parse properties.browser_platform_version /(?<major_version>^[^\\.]+)/\n| fields concat(properties.browser_platform_name, ' ', major_version) as platform\n| stats count() as error_count by platform\n| sort error_count desc",
        "region": "${var.region}",
        "stacked": false,
        "title": "Image capture failures by mobile platform",
        "view": "bar"
      }
    },
    {
      "height": 8,
      "width": 10,
      "y": 62,
      "x": 14,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @message\n| filter name = 'Frontend: IdV: Image capture failed'\n| stats count() as error_count by properties.event_properties.error as failure_reason\n| sort error_count desc",
        "region": "${var.region}",
        "stacked": false,
        "title": "Image capture failure by failure reason",
        "view": "bar"
      }
    },
    {
      "height": 2,
      "width": 24,
      "y": 60,
      "x": 0,
      "type": "text",
      "properties": {
        "markdown": "# Image capture failures\n\nThese are statistics pulled from logs that are written when the Acuant SDK fails to launch or crashes"
      }
    },
    {
      "height": 5,
      "width": 24,
      "y": 0,
      "x": 0,
      "type": "text",
      "properties": {
        "markdown": "# Document capture funnel and success rate\n\nThe funnel for the steps to make it through the document capture step and the success rate at that step are shown below.\n\nA few notes:\n\n- The data in the funnel is coalesced around sessions. Each bar represents the number of sessions that successfully reached that step.\n- The Acuant SDK initialization step is lower than following steps because users on desktop devices do not load the Acuant SDK.\n- Success rate in the document capture step success rate chart is described as the number of sessions that successfully complete the vendor check at the end divided by sessions that enter the step. In essence, the last bar in the funnel divided by the first\n- Success rate in the document capture vendor success rate chart is described as the number of sessions that complete the vendor check at the end divided by sessions that submit images. In essence, the second to last bar in the funnel divided by the last"
      }
    },
    {
      "height": 2,
      "width": 24,
      "y": 77,
      "x": 0,
      "type": "text",
      "properties": {
        "markdown": "# Vendor results\n\nThe following section describes the results we receive when documents are sent to the vendor to be verified"
      }
    },
    {
      "height": 2,
      "width": 24,
      "y": 33,
      "x": 0,
      "type": "text",
      "properties": {
        "markdown": "# Attempt counts\n\nThis section describes how often users need to submit before successfully completing the document capture step"
      }
    },
    {
      "height": 8,
      "width": 18,
      "y": 35,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth image upload vendor submitted'\n| fields @timestamp, @message, properties.event_properties.success as @success, !properties.event_properties.success as @failure\n| stats sum(@success) as successful_transactions, sum(@failure) as failed_transactions by properties.event_properties.attempts as attempts\n| sort attempts asc",
        "region": "${var.region}",
        "stacked": false,
        "title": "Transaction status by attempt count",
        "view": "bar"
      }
    },
    {
      "height": 8,
      "width": 6,
      "y": 35,
      "x": 18,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth image upload vendor submitted'\n| filter properties.event_properties.success\n| filter properties.new_event\n| fields properties.event_properties.attempts as attempts\n| stats avg(attempts) as mean, pct(attempts, 50) as median_, pct(attempts, 95) as p95",
        "region": "${var.region}",
        "stacked": false,
        "title": "Number of submissions before success",
        "view": "table"
      }
    },
    {
      "height": 5,
      "width": 20,
      "y": 22,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name in ['IdV: doc auth image upload form submitted', 'IdV: doc auth image upload vendor submitted']\n| fields (name = 'IdV: doc auth image upload form submitted') as @image_form_submitted,\n  (name = 'IdV: doc auth image upload vendor submitted') as\n@images_vendor_submitted_success\n| filter properties.event_properties.success and properties.new_event\n| stats sum(@images_vendor_submitted_success) / sum(@image_form_submitted) * 100 as vendor_success_rate by bin(1hr)",
        "region": "${var.region}",
        "stacked": false,
        "title": "Document capture vendor success rate - How many sessions that submitted an image were able to pass this step?",
        "view": "timeSeries"
      }
    },
    {
      "height": 5,
      "width": 4,
      "y": 22,
      "x": 20,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name in ['IdV: doc auth image upload form submitted', 'IdV: doc auth image upload vendor submitted']\n| fields (name = 'IdV: doc auth image upload form submitted') as @image_form_submitted,\n  (name = 'IdV: doc auth image upload vendor submitted') as\n@images_vendor_submitted_success\n| filter properties.event_properties.success and properties.new_event\n| stats sum(@images_vendor_submitted_success) / sum(@image_form_submitted) * 100 as vendor_success_rate",
        "region": "${var.region}",
        "stacked": false,
        "title": "Document capture vendor success rate",
        "view": "table"
      }
    },
    {
      "height": 7,
      "width": 24,
      "y": 70,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @message\n| filter name = 'Frontend: IdV: Image capture failed'\n| fields (properties.event_properties.error = 'iOS 15 GPU Highwater failure (SEQUENCE_BREAK_CODE)') as @ios15_crash\n| stats count() as total_error_count, sum(@ios15_crash) as ios_15_crash by bin(15min)\n| sort error_count desc",
        "region": "${var.region}",
        "stacked": false,
        "title": "Image capture failure volume over time",
        "view": "timeSeries"
      }
    },
    {
      "height": 6,
      "width": 24,
      "y": 11,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp,\n  @message,\n  (name == 'IdV: doc auth document_capture visited' and\nproperties.new_event) as @document_capture_visited,\n  (name == 'Frontend: IdV: Acuant SDK loaded' and properties.new_event) as\n@acuant_sdk_loaded,\n  (name == 'Frontend: IdV: front image clicked' and properties.new_event)\nas @front_image_clicked,\n  (name = 'Frontend: IdV: front image added' and properties.new_event) as\n@front_image_added,\n  (name = 'Frontend: IdV: back image clicked' and properties.new_event) as\n@back_image_clicked,\n  (name = 'Frontend: IdV: back image added' and properties.new_event) as\n@back_image_added,\n  (name = 'IdV: doc auth image upload form submitted' and\nproperties.new_event) as @image_form_submitted,\n  (name = 'IdV: doc auth image upload vendor submitted' and\nproperties.event_properties.success and properties.new_session_success_state) as @images_vendor_submitted_success\n| stats (sum(@document_capture_visited) - sum(@front_image_clicked)) / (sum(@document_capture_visited) - sum(@images_vendor_submitted_success)) * 100 as front_image_clicked,\n  (sum(@front_image_clicked) - sum(@front_image_added))\n/ (sum(@document_capture_visited) - sum(@images_vendor_submitted_success)) * 100 as front_image_added,\n  (sum(@front_image_added) - sum(@back_image_clicked))\n/ (sum(@document_capture_visited) - sum(@images_vendor_submitted_success)) * 100 as back_image_clicked,\n  (sum(@back_image_clicked) - sum(@back_image_added))\n/ (sum(@document_capture_visited) - sum(@images_vendor_submitted_success)) * 100 as back_image_added,\n  (sum(@back_image_added) - sum(@image_form_submitted))\n/ (sum(@document_capture_visited) - sum(@images_vendor_submitted_success)) * 100 as image_form_submitted,\n  (sum(@image_form_submitted) - sum(@images_vendor_submitted_success))\n/ (sum(@document_capture_visited) - sum(@images_vendor_submitted_success)) * 100 as images_vendor_submitted_success\n  by bin(1hour)",
        "region": "${var.region}",
        "stacked": true,
        "title": "Document capture funnel drop-off rates",
        "view": "timeSeries"
      }
    },
    {
      "height": 6,
      "width": 24,
      "y": 85,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name like /Frontend: IdV: .* image added/\n| filter ispresent(properties.event_properties.assessment)\n| fields (properties.event_properties.assessment = 'glare') as @glare, (properties.event_properties.assessment = 'blurry') as @blurry, (properties.event_properties.assessment = 'success') as @success\n| stats sum(@glare) / count() as glare, sum(@blurry) / count() as blurry, sum(@success) / count() as success by bin(10min)",
        "region": "${var.region}",
        "stacked": true,
        "view": "timeSeries",
        "title": "Acuant SDK image assessment over time"
      }
    },
    {
      "height": 6,
      "width": 24,
      "y": 91,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter name like /Frontend: IdV: .* image added/\n| filter ispresent(properties.event_properties.assessment)\n| fields (properties.event_properties.assessment = 'glare') as @glare, (properties.event_properties.assessment = 'blurry') as @blurry, (properties.event_properties.assessment = 'success') as @success\n| stats sum(@glare) as glare, sum(@blurry) as blurry, sum(@success) as success by bin(10min)",
        "region": "${var.region}",
        "stacked": true,
        "title": "Acuant SDK image assessment VOLUME over time",
        "view": "timeSeries"
      }
    }
  ]
}
  EOF
}
