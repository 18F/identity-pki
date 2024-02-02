resource "aws_cloudwatch_dashboard" "idv_verify_your_identity_overview" {
  dashboard_name = "${var.env_name}-idv-verify-your-identity-overview"

  dashboard_body = jsonencode(
    {
      "variables" : [
        {
          "type" : "pattern",
          "pattern" : "ispresent\\(properties\\.service_provider\\) or isblank\\(properties\\.service_provider\\)",
          "inputType" : "select",
          "id" : "sp",
          "label" : "Service provider",
          "defaultValue" : "ispresent(properties.service_provider) or isblank(properties.service_provider)",
          "visible" : true,
          "values" : concat(
            [
              {
                "value" : "ispresent(properties.service_provider) or isblank(properties.service_provider)",
                "label" : "All"
              }
            ],
            [
              for sp in var.idp_dashboard_filter_sps :
              join("", [
                "(",
                join(" or ", [for issuer in sp.issuers : "properties.service_provider = ${jsonencode(issuer)}"]),
                "),",
                sp.name
              ])
            ]
          )
        }
      ],
      "widgets" : [
        {
          "height" : 4,
          "width" : 8,
          "y" : 2,
          "x" : 0,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth verify proofing results'\n| filter ispresent(properties.service_provider) or isblank(properties.service_provider)\n| fields properties.event_properties.success as overall_success,\n\n    !overall_success as overall_failure,\n\n    properties.event_properties.proofing_results.context.stages.resolution.success\n\n        as iv_success,\n\n    properties.event_properties.proofing_results.context.stages.state_id.success\n\n        as aamva_success\n\n| stats sum(overall_success) + sum(overall_failure) as submitted,\n\n    sum(overall_success) as success,\n\n    sum(overall_failure) as failure,\n\n    sum(overall_success) / submitted * 100 as success_rate,\n\n    sum(iv_success) / submitted * 100 as iv_success_rate,\n\n    sum(aamva_success) / submitted * 100 as aamva_success_rate\n",
            "region" : var.region,
            "stacked" : false,
            "title" : "Overall Success Rate",
            "view" : "table"
          }
        },
        {
          "height" : 5,
          "width" : 8,
          "y" : 6,
          "x" : 0,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth verify proofing results'\n| filter ispresent(properties.service_provider) or isblank(properties.service_provider)\n| fields\n\n    properties.event_properties.success as overall_success,\n\n    !overall_success as overall_failure,\n\n    properties.event_properties.proofing_results.context.stages.resolution.success\n\n        as iv_success,\n\n    !iv_success as iv_failure,\n\n    properties.event_properties.proofing_results.context.stages.state_id.success\n\n        as aamva_success,\n\n    !aamva_success as aamva_failure,\n\n    overall_failure and iv_failure and aamva_success as iv_only_failure,\n\n    overall_failure and iv_success and aamva_failure as aamva_only_failure,\n\n    overall_failure and iv_failure and aamva_failure as both_failure,\n\n    overall_failure and iv_success and aamva_success as other_failure\n\n| stats sum(iv_only_failure) as iv_only,\n\n    sum(aamva_only_failure) as aamva_only,\n\n    sum(both_failure) as both,\n\n    sum(other_failure) as other,\n\n    sum(iv_only_failure) / sum(overall_failure) * 100 as iv_only_rate,\n\n    sum(aamva_only_failure) / sum(overall_failure) * 100 as aamva_only_rate,\n\n    sum(both_failure) / sum(overall_failure) * 100 as both_rate,\n\n    sum(other) / sum(overall_failure) * 100 as other_rate",
            "region" : var.region,
            "stacked" : false,
            "title" : "",
            "view" : "table"
          }
        },
        {
          "height" : 5,
          "width" : 8,
          "y" : 6,
          "x" : 8,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth verify proofing results'\n| filter ispresent(properties.service_provider) or isblank(properties.service_provider)\n| fields\n\n    properties.event_properties.success as overall_success,\n\n    !overall_success as overall_failure,\n\n    properties.event_properties.proofing_results.context.stages.resolution.success\n\n as iv_success,\n\n    !iv_success as iv_failure,\n\n    properties.event_properties.proofing_results.context.stages.state_id.success\n\n as aamva_success,\n\n    !aamva_success as aamva_failure,\n\n    overall_failure and iv_failure and aamva_success as iv_only_failure,\n\n    overall_failure and iv_success and aamva_failure as aamva_only_failure,\n\n    overall_failure and iv_failure and aamva_failure as both_failure,\n\n    overall_failure and iv_success and aamva_success as other_failure\n\n| stats sum(iv_only_failure) / sum(overall_failure) * 100 as iv_only,\n\n    sum(aamva_only_failure) / sum(overall_failure) * 100\n\n as aamva_only,\n\n    sum(both_failure) / sum(overall_failure) * 100 as both,\n\n    sum(other_failure) / sum(overall_failure) * 100 as other\n\n    by bin(1y)",
            "region" : var.region,
            "stacked" : false,
            "title" : "",
            "view" : "bar"
          }
        },
        {
          "height" : 5,
          "width" : 8,
          "y" : 6,
          "x" : 16,
          "type" : "text",
          "properties" : {
            "markdown" : "### Failure Breakdown by Service\n\n\nLooking at those events with an overall failure, we show both raw counts and the percentage of\nfailures attributed to each of the following:\n\n\nField | Description\n---|---\n`iv_only` | Failures due to InstantVerify only\n`aamva_only` | Failures due to AAMVA only\n`both` | Both InstantVerify and AAMVA reported failure\n`other`* | Both InstantVerify and AAMVA succeeded, but the overall result is failure\n\n\n**example of `other` would be if the call to ThreatMetrix raised an exception*\n\n\nNote: if the call to ThreatMetrix results in flagging the user for review, the overall success is not affected."
          }
        },
        {
          "height" : 4,
          "width" : 8,
          "y" : 2,
          "x" : 16,
          "type" : "text",
          "properties" : {
            "markdown" : "### Overall Success Rate\n\nLooking at all Verify Your Information results, we show the following:\n\nField | Description\n---|---\n`submitted` | Total number of attempts to verify\n`success` | Number of overall successful attempts\n`failure` | Number of submissions that failed for any reason\n`success_rate` | Percentage of submissions that succeed\n`iv_success_rate` | Percentage of submissions that passed InstantVerify\n`aamva_success_rate` | Percentage of submissions that passed AAMVA"
          }
        },
        {
          "height" : 6,
          "width" : 9,
          "y" : 13,
          "x" : 15,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth verify proofing results' and\n\n    properties.event_properties.proofing_results.context.stages.state_id.mva_exception\n\n| filter ispresent(properties.service_provider) or isblank(properties.service_provider)\n| fields\n\n    properties.event_properties.proofing_results.context.stages.state_id.state_id_jurisdiction\n\n        as state\n\n| stats count() as exceptions by state\n| sort exceptions desc",
            "region" : var.region,
            "stacked" : false,
            "title" : "",
            "view" : "table"
          }
        },
        {
          "height" : 6,
          "width" : 8,
          "y" : 13,
          "x" : 7,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth verify proofing results' and\n\n    !isblank(properties.event_properties.proofing_results.context.stages.state_id.exception)\n\n| filter ispresent(properties.service_provider) or isblank(properties.service_provider)\n| fields\n\n    properties.event_properties.proofing_results.context.stages.state_id.mva_exception\n\n        as mva_exception,\n\n    !mva_exception as dldv_exception\n\n| stats sum(mva_exception) as mva_exceptions,\n\n    sum(dldv_exception) as dldv_exceptions\n",
            "region" : var.region,
            "stacked" : false,
            "title" : "",
            "view" : "table"
          }
        },
        {
          "height" : 6,
          "width" : 7,
          "y" : 13,
          "x" : 0,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth verify proofing results' and\n    !properties.event_properties.proofing_results.context.stages.state_id.success\n| filter ispresent(properties.service_provider) or isblank(properties.service_provider)\n| parse @message /\"state_id\":.+?\"errors\":\\{(?<parsed_errors>[^\\}]*)\\}/\n| fields\n    !isblank(parsed_errors) as error,\n    !isblank(properties.event_properties.proofing_results.context.stages.state_id.exception)\n        as exception\n| stats sum(error) as errors,\n    sum(exception) as exceptions",
            "region" : var.region,
            "stacked" : false,
            "title" : "",
            "view" : "table"
          }
        },
        {
          "height" : 2,
          "width" : 24,
          "y" : 11,
          "x" : 0,
          "type" : "text",
          "properties" : {
            "markdown" : "### AAMVA Failures\n\nBelow, we show a breakdown of AAMVA failures by Error or Exception (i.e., the user failed to pass vs. the system failed to provide an answer). For exceptions, we break those down between exceptions from individual MVAs vs. DLDV (AAMVA) as a whole. Finally, for MVA exceptions, we break those out by state."
          }
        },
        {
          "height" : 2,
          "width" : 24,
          "y" : 0,
          "x" : 0,
          "type" : "text",
          "properties" : {
            "markdown" : "## Verify Your Information - Results\n\nThis dashboard shows the results of a user attempting to verify their PII. As of August 2023 we use LexisNexis InstantVerify, AAMVA, and ThreatMetrix to evaluate a user's data. We show the success rate (overall, IV, and AAMVA) and then break down failures to gain insight."
          }
        },
        {
          "height" : 4,
          "width" : 8,
          "y" : 2,
          "x" : 8,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth verify proofing results'\n| filter ispresent(properties.service_provider) or isblank(properties.service_provider)\n| fields properties.event_properties.success as overall,\n\n    !overall as overall_failure,\n\n    properties.event_properties.proofing_results.context.stages.resolution.success\n\n        as iv,\n\n    properties.event_properties.proofing_results.context.stages.state_id.success\n\n        as aamva\n\n| stats sum(overall) / (sum(overall) + sum(overall_failure)) * 100\n\n        as overall_success,\n\n    sum(iv) / (sum(overall) + sum(overall_failure)) * 100\n\n        as iv_success,\n\n    sum(aamva) / (sum(overall) + sum(overall_failure)) * 100\n\n        as aamva_success\n\n    by bin(1hr)",
            "region" : var.region,
            "stacked" : false,
            "title" : "",
            "view" : "timeSeries"
          }
        },
        {
          "height" : 3,
          "width" : 24,
          "y" : 19,
          "x" : 0,
          "type" : "text",
          "properties" : {
            "markdown" : "### Dig Even Deeper\nFor a more detailed breakdown of which attributes are failing, see the [Identity resolution attribute failures dashboard](#dashboards:name=prod-idv-resolution-failed-attributes).\n\n\nFor a more detailed breakdown of the AAMVA failures, see the [mva timeouts dashboard](#dashboards:name=prod-idv-mva-timeouts)."
          }
        }
      ]
    }
  )
}
