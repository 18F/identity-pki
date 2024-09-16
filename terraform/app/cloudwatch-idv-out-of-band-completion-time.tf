module "dashboard-idv-out-of-band-completion-time" {
  source = "../modules/cloudwatch_dashboard"

  dashboard_name = "${var.env_name}-idv-out-of-band-completion-time"

  ## Uncomment the filter_sps var below to add an "SP" filter to the dashboard.
  ## For this to work, you need to add the following filter to _all_ relevant queries in your dashboard:
  ##
  ##   | filter ispresent(properties.service_provider) or not ispresent(properties.service_provider)
  ##
  # filter_sps = var.idp_dashboard_filter_sps

  # dashboard_definition contains the JSON exported from Amazon Cloudwatch via bin/copy-cloudwatch-dashboard.
  # If you make changes to your dashboard, just re-run this command:
  #
  #   aws-vault exec prod-power -- bin/copy-cloudwatch-dashboard --in jh-idv-out-of-band-completion-time --out cloudwatch-idv-out-of-band-completion-time.tf
  #
  # Then commit your changes back to this repository.
  #
  dashboard_definition = {
    "start" : "-PT168H",
    "widgets" : [
      {
        "height" : 8,
        "width" : 24,
        "y" : 6,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name in ['IdV: enter verify by mail code submitted', 'GetUspsProofingResultsJob: Enrollment status updated', 'Fraud: Profile review passed']\n| filter ispresent(properties.event_properties.profile_age_in_seconds)\n| filter (name = 'IdV: enter verify by mail code submitted' and properties.event_properties.success = 1 and !properties.event_properties.pending_in_person_enrollment and !properties.event_properties.fraud_check_failed) or (name != 'IdV: enter verify by mail code submitted')\n| filter (name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.passed = 1 and properties.event_properties.tmx_status not in ['threatmetrix_review', 'threatmetrix_reject']) or (name != 'GetUspsProofingResultsJob: Enrollment status updated')\n| filter (name = 'Fraud: Profile review passed' and properties.event_properties.success = 1) or (name != 'Fraud: Profile review passed')\n| fields ceil(properties.event_properties.profile_age_in_seconds / (3600 * 24)) as profile_age_in_days\n| stats count(*) as event_count by profile_age_in_days\n| sort profile_age_in_days asc\n| limit 90",
          "region" : var.region,
          "stacked" : false,
          "title" : "Profile age at verification: All events",
          "view" : "bar"
        }
      },
      {
        "height" : 3,
        "width" : 24,
        "y" : 14,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name in ['IdV: enter verify by mail code submitted', 'GetUspsProofingResultsJob: Enrollment status updated', 'Fraud: Profile review passed']\n| filter ispresent(properties.event_properties.profile_age_in_seconds)\n| filter (name = 'IdV: enter verify by mail code submitted' and properties.event_properties.success = 1 and !properties.event_properties.pending_in_person_enrollment and !properties.event_properties.fraud_check_failed) or (name != 'IdV: enter verify by mail code submitted')\n| filter (name = 'GetUspsProofingResultsJob: Enrollment status updated' and properties.event_properties.passed = 1 and properties.event_properties.tmx_status not in ['threatmetrix_review', 'threatmetrix_reject']) or (name != 'GetUspsProofingResultsJob: Enrollment status updated')\n| filter (name = 'Fraud: Profile review passed' and properties.event_properties.success = 1) or (name != 'Fraud: Profile review passed')\n| fields properties.event_properties.profile_age_in_seconds / (3600 * 24) as profile_age_in_days\n| stats count(*) as number_of_events, avg(profile_age_in_days) as average_days, pct(profile_age_in_days, 50) as median_days, min(profile_age_in_days) as min_days, max(profile_age_in_days) as max_days\n",
          "region" : var.region,
          "stacked" : false,
          "title" : "Profile age at verification: All events",
          "view" : "table"
        }
      },
      {
        "height" : 8,
        "width" : 24,
        "y" : 17,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: enter verify by mail code submitted'\n| filter ispresent(properties.event_properties.profile_age_in_seconds)\n| filter properties.event_properties.success = 1 and !properties.event_properties.pending_in_person_enrollment and !properties.event_properties.fraud_check_failed\n| fields ceil(properties.event_properties.profile_age_in_seconds / (3600 * 24)) as profile_age_in_days\n| stats count(*) as event_count by profile_age_in_days\n| sort profile_age_in_days asc\n| limit 90",
          "region" : var.region,
          "stacked" : false,
          "title" : "Profile age at verification: Verify-by-mail",
          "view" : "bar"
        }
      },
      {
        "height" : 3,
        "width" : 24,
        "y" : 25,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: enter verify by mail code submitted'\n| filter ispresent(properties.event_properties.profile_age_in_seconds)\n| filter properties.event_properties.success = 1 and !properties.event_properties.pending_in_person_enrollment and !properties.event_properties.fraud_check_failed\n| fields properties.event_properties.profile_age_in_seconds / (3600 * 24) as profile_age_in_days\n| stats count(*) as number_of_events, avg(profile_age_in_days) as average_days, pct(profile_age_in_days, 50) as median_days, min(profile_age_in_days) as min_days, max(profile_age_in_days) as max_days",
          "region" : var.region,
          "stacked" : false,
          "title" : "Profile age at verification: Verify-by-mail",
          "view" : "table"
        }
      },
      {
        "height" : 8,
        "width" : 24,
        "y" : 28,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name ='GetUspsProofingResultsJob: Enrollment status updated'\n| filter ispresent(properties.event_properties.profile_age_in_seconds)\n| filter properties.event_properties.passed = 1 and properties.event_properties.tmx_status not in ['threatmetrix_review', 'threatmetrix_reject']\n| fields ceil(properties.event_properties.profile_age_in_seconds / (3600 * 24)) as profile_age_in_days\n| stats count(*) as event_count by profile_age_in_days\n| sort profile_age_in_days asc\n| limit 90",
          "region" : var.region,
          "stacked" : false,
          "title" : "Profile age at verification: In-person proofing",
          "view" : "bar"
        }
      },
      {
        "height" : 3,
        "width" : 24,
        "y" : 36,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name ='GetUspsProofingResultsJob: Enrollment status updated'\n| filter ispresent(properties.event_properties.profile_age_in_seconds)\n| filter properties.event_properties.passed = 1 and properties.event_properties.tmx_status not in ['threatmetrix_review', 'threatmetrix_reject']\n| fields properties.event_properties.profile_age_in_seconds / (3600 * 24) as profile_age_in_days\n| stats count(*) as number_of_events, avg(profile_age_in_days) as average_days, pct(profile_age_in_days, 50) as median_days, min(profile_age_in_days) as min_days, max(profile_age_in_days) as max_days\n",
          "region" : var.region,
          "stacked" : false,
          "title" : "Profile age at verification: In-person proofing",
          "view" : "table"
        }
      },
      {
        "height" : 8,
        "width" : 24,
        "y" : 39,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name ='Fraud: Profile review passed'\n| filter ispresent(properties.event_properties.profile_age_in_seconds)\n| filter properties.event_properties.success = 1\n| fields ceil(properties.event_properties.profile_age_in_seconds / (3600 * 24)) as profile_age_in_days\n| stats count(*) as event_count by profile_age_in_days\n| sort profile_age_in_days asc\n| limit 90",
          "region" : var.region,
          "stacked" : false,
          "title" : "Profile age at verification: Fraud review",
          "view" : "bar"
        }
      },
      {
        "height" : 3,
        "width" : 24,
        "y" : 47,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name ='Fraud: Profile review passed'\n| filter ispresent(properties.event_properties.profile_age_in_seconds)\n| filter properties.event_properties.success = 1\n| fields properties.event_properties.profile_age_in_seconds / (3600 * 24) as profile_age_in_days\n| stats count(*) as number_of_events, avg(profile_age_in_days) as average_days, pct(profile_age_in_days, 50) as median_days, min(profile_age_in_days) as min_days, max(profile_age_in_days) as max_days\n",
          "region" : var.region,
          "stacked" : false,
          "title" : "Profile age at verification: Fraud review",
          "view" : "table"
        }
      },
      {
        "type" : "text",
        "x" : 0,
        "y" : 0,
        "width" : 24,
        "height" : 6,
        "properties" : {
          "markdown" : "# Time to proof for out-of-band flows\n\n\n\n\nThis dashboard shows how long it takes people to proof who finish the proofing workflow with a pending profile. This includes people in the following flows:\n\n\n\n\n- Verify-by-mail\n- In-person proofing\n- Fraud review\n\n\n\n\nThis is done by logging the age of the profile when a user completes one of these flows and has a verified profile.\n\n\nThis dashboard includes charts and statistics for all out-of-band flows and for the individual flows."
        }
      }
    ]
  }
}
