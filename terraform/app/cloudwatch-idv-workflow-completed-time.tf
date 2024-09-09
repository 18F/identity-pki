module "dashboard-idv-workflow-completed-time" {
  source = "../modules/cloudwatch_dashboard"

  dashboard_name = "${var.env_name}-idv-workflow-completed-time"

  ## Uncomment the filter_sps var below to add an "SP" filter to the dashboard.
  ## For this to work, you need to add the following filter to _all_ relevant queries in your dashboard:
  ##
  ##   | filter ispresent(properties.service_provider) or not ispresent(properties.service_provider)
  ##
  # filter_sps = var.idp_dashboard_filter_sps

  # dashboard_definition contains the JSON exported from Amazon Cloudwatch via bin/copy-cloudwatch-dashboard.
  # If you make changes to your dashboard, just re-run this command:
  #
  #   aws-vault exec prod-power -- bin/copy-cloudwatch-dashboard --in jh-idv-workflow-completed-time --out cloudwatch-idv-workflow-completed-time.tf
  #
  # Then commit your changes back to this repository.
  #
  dashboard_definition = {
    "variables" : [
      {
        "type" : "pattern",
        "pattern" : "biometric_filter_setting",
        "inputType" : "select",
        "id" : "biometric_filter",
        "label" : "Biometric Filter",
        "defaultValue" : "''",
        "visible" : true,
        "values" : [
          {
            "value" : "''",
            "label" : "All"
          },
          {
            "value" : "'1'",
            "label" : "Biometric"
          },
          {
            "value" : "'0'",
            "label" : "Non-biometric"
          }
        ]
      },
      {
        "type" : "pattern",
        "pattern" : "gpo_filter_setting",
        "inputType" : "select",
        "id" : "gpo_filter",
        "label" : "GPO Filter",
        "defaultValue" : "''",
        "visible" : true,
        "values" : [
          {
            "value" : "''",
            "label" : "All"
          },
          {
            "value" : "'1'",
            "label" : "GPO Pending"
          },
          {
            "value" : "'0'",
            "label" : "Not GPO Pending"
          }
        ]
      },
      {
        "type" : "pattern",
        "pattern" : "ipp_filter_setting",
        "inputType" : "select",
        "id" : "ipp_pending",
        "label" : "IPP Filter",
        "defaultValue" : "''",
        "visible" : true,
        "values" : [
          {
            "value" : "''",
            "label" : "All"
          },
          {
            "value" : "'1'",
            "label" : "IPP Pending"
          },
          {
            "value" : "'0'",
            "label" : "Not IPP Pending"
          }
        ]
      }
    ],
    "widgets" : [
      {
        "height" : 3,
        "width" : 24,
        "y" : 16,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message \n| filter name = 'IdV: final resolution'\n| fields ispresent(properties.sp_request.biometric_comparison) as biometric_comparison\n| filter strcontains(biometric_comparison, biometric_filter_setting)\n| filter strcontains(properties.event_properties.gpo_verification_pending, gpo_filter_setting)\n| filter strcontains(properties.event_properties.in_person_verification_pending, ipp_filter_setting)\n| fields properties.event_properties.proofing_workflow_time_in_seconds / 60 as proofing_workflow_time_in_minutes \n| stats count(*) as number_of_events, avg(proofing_workflow_time_in_minutes) as average_minutes, pct(proofing_workflow_time_in_minutes, 50) as median_minutes, min(proofing_workflow_time_in_minutes) as min_minutes, max(proofing_workflow_time_in_minutes) as max_minutes\n",
          "region" : var.region,
          "stacked" : false,
          "title" : "",
          "view" : "table"
        }
      },
      {
        "height" : 10,
        "width" : 24,
        "y" : 6,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message \n| filter name = 'IdV: final resolution'\n| filter ispresent(properties.event_properties.proofing_workflow_time_in_seconds)\n| fields ispresent(properties.sp_request.biometric_comparison) as biometric_comparison\n| filter strcontains(biometric_comparison, biometric_filter_setting)\n| filter strcontains(properties.event_properties.gpo_verification_pending, gpo_filter_setting)\n| filter strcontains(properties.event_properties.in_person_verification_pending, ipp_filter_setting)\n| fields ceil(properties.event_properties.proofing_workflow_time_in_seconds / 60) as proofing_workflow_time_in_minutes \n| stats count(*) as number_of_events by proofing_workflow_time_in_minutes\n| sort proofing_workflow_time_in_minutes asc\n| limit 30",
          "region" : var.region,
          "stacked" : false,
          "title" : "",
          "view" : "bar"
        }
      },
      {
        "type" : "text",
        "x" : 0,
        "y" : 0,
        "width" : 24,
        "height" : 6,
        "properties" : {
          "markdown" : "# Time to complete proofing workflow\n\n\n\n\nThis control shows how long it takes users to complete the proofing workflow.\n\n\n\n\nThe timer starts when the user first visits the welcome step. The timer shows how long it takes to successfully proof and re-enter the password in that session. Once the user successfully enters their password their proofed data is stored and associated with their account.\n\n\n\n\nUsers who do not successfully complete the enter password step are not counted.\n\n\nUse the dropdowns to restrict to biometric, GPO, and IPP users.\n\n\n\n\n**The time units are minutes**"
        }
      }
    ]
  }
}
