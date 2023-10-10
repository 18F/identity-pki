resource "aws_cloudwatch_dashboard" "get_to_yes" {
  dashboard_name = "${var.env_name}-get-to-yes"

  dashboard_body = <<EOF
    {
  "widgets": [
    {
      "height": 6,
      "width": 12,
      "y": 5,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter ispresent(properties.event_properties.proofing_results.context.resolution_adjudication_reason)\n| stats \n  count(*) as count by properties.event_properties.proofing_results.context.resolution_adjudication_reason as `Adjudication Reason`\n| sort count desc",
        "region": "${var.region}",
        "stacked": false,
        "title": "Get to yes adjudication reasons",
        "view": "table"
      }
    },
    {
      "height": 6,
      "width": 12,
      "y": 5,
      "x": 12,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter ispresent(properties.event_properties.proofing_results.context.resolution_adjudication_reason)\n| stats \n  count(*) as `Reason Count` by properties.event_properties.proofing_results.context.resolution_adjudication_reason as `Adjudication Reason`\n| sort `Reason Count` desc",
        "region": "${var.region}",
        "stacked": false,
        "title": "Get to yes adjudication reasons – Visualization",
        "view": "pie"
      }
    },
    {
      "height": 6,
      "width": 12,
      "y": 14,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message, properties.event_properties.proofing_results.context.resolution_adjudication_reason as `reason`\n| filter ispresent(properties.event_properties.proofing_results.context.resolution_adjudication_reason)\n| fields \n  (properties.event_properties.proofing_results.context.resolution_adjudication_reason = 'pass_resolution_and_state_id') as @full_pass,\n  (properties.event_properties.proofing_results.context.resolution_adjudication_reason = 'state_id_covers_failed_resolution') as @get_to_yes_pass,\n  (properties.event_properties.proofing_results.context.resolution_adjudication_reason = 'fail_resolution_without_state_id_coverage') as @fail_without_state_id_coverage,\n  (properties.event_properties.proofing_results.context.resolution_adjudication_reason = 'fail_resolution_skip_state_id') as @fail_resolution_skip_state_id,\n  (properties.event_properties.proofing_results.context.resolution_adjudication_reason = 'fail_state_id') as @fail_state_id\n| stats \n  sum(@full_pass) / (sum(@full_pass) + sum(@get_to_yes_pass) + sum(@fail_without_state_id_coverage) + sum(@fail_resolution_skip_state_id) + sum(@fail_state_id)) * 100 as `Pass Rate without Get to Yes`,\n  (sum(@full_pass) + sum(@get_to_yes_pass)) / (sum(@full_pass) + sum(@get_to_yes_pass) + sum(@fail_without_state_id_coverage) + sum(@fail_resolution_skip_state_id) + sum(@fail_state_id)) * 100 as `Pass Rate with Get to Yes`,\n  `Pass Rate with Get to Yes` - `Pass Rate without Get to Yes` as `Get to Yes Impact`\n  by bin(1h)",
        "region": "${var.region}",
        "stacked": false,
        "title": "Get to yes impact over time – Visualization",
        "view": "timeSeries"
      }
    },
    {
      "height": 6,
      "width": 12,
      "y": 14,
      "x": 12,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message, properties.event_properties.proofing_results.context.resolution_adjudication_reason as `reason`\n| filter ispresent(properties.event_properties.proofing_results.context.resolution_adjudication_reason)\n| fields \n  (properties.event_properties.proofing_results.context.resolution_adjudication_reason = 'pass_resolution_and_state_id') as @full_pass,\n  (properties.event_properties.proofing_results.context.resolution_adjudication_reason = 'state_id_covers_failed_resolution') as @get_to_yes_pass,\n  (properties.event_properties.proofing_results.context.resolution_adjudication_reason = 'fail_resolution_without_state_id_coverage') as @fail_without_state_id_coverage,\n  (properties.event_properties.proofing_results.context.resolution_adjudication_reason = 'fail_resolution_skip_state_id') as @fail_resolution_skip_state_id,\n  (properties.event_properties.proofing_results.context.resolution_adjudication_reason = 'fail_state_id') as @fail_state_id\n| stats \n  (sum(@full_pass) + sum(@get_to_yes_pass) + sum(@fail_without_state_id_coverage) + sum(@fail_resolution_skip_state_id) + sum(@fail_state_id)) as `All Transactions`,\n  sum(@get_to_yes_pass) as `Get to Yes Passes`\n  by bin(1h)",
        "region": "${var.region}",
        "stacked": false,
        "title": "Transactions over time – Visualization",
        "view": "timeSeries"
      }
    },
    {
      "height": 3,
      "width": 24,
      "y": 11,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message, properties.event_properties.proofing_results.context.resolution_adjudication_reason as `reason`\n| filter ispresent(properties.event_properties.proofing_results.context.resolution_adjudication_reason)\n| fields \n  (properties.event_properties.proofing_results.context.resolution_adjudication_reason = 'pass_resolution_and_state_id') as @full_pass,\n  (properties.event_properties.proofing_results.context.resolution_adjudication_reason = 'state_id_covers_failed_resolution') as @get_to_yes_pass,\n  (properties.event_properties.proofing_results.context.resolution_adjudication_reason = 'fail_resolution_without_state_id_coverage') as @fail_without_state_id_coverage,\n  (properties.event_properties.proofing_results.context.resolution_adjudication_reason = 'fail_resolution_skip_state_id') as @fail_resolution_skip_state_id,\n  (properties.event_properties.proofing_results.context.resolution_adjudication_reason = 'fail_state_id') as @fail_state_id\n| stats \n  sum(@full_pass) / (sum(@full_pass) + sum(@get_to_yes_pass) + sum(@fail_without_state_id_coverage) + sum(@fail_resolution_skip_state_id) + sum(@fail_state_id)) * 100 as `Pass Rate without Get to Yes`,\n  (sum(@full_pass) + sum(@get_to_yes_pass)) / (sum(@full_pass) + sum(@get_to_yes_pass) + sum(@fail_without_state_id_coverage) + sum(@fail_resolution_skip_state_id) + sum(@fail_state_id)) * 100 as `Pass Rate with Get to Yes`,\n  `Pass Rate with Get to Yes` - `Pass Rate without Get to Yes` as `Get to Yes Impact`",
        "region": "${var.region}",
        "stacked": false,
        "title": "Get to yes transaction impact over time",
        "view": "table"
      }
    },
    {
      "height": 5,
      "width": 24,
      "y": 0,
      "x": 0,
      "type": "text",
      "properties": {
        "markdown": "# Get to Yes\n\nKey\n\n\n* **pass_resolution_and_state_id** –  Both AAMVA and LexisNexis passed. This is considered a *success*.\n* **state_id_covers_failed_resolution** – InstantVerify failed, but AAMVA passed and the AAMVA response covers the attributes that failed in InstantVerify. This is considered a *success*.\n* **fail_state_id** – AAMVA failed. This is considered a *fail*.\n* **fail_resolution_skip_state_id** – InstantVerify failed and AAMVA is not available for the state. This is considered a *fail*.\n* **fail_resolution_without_state_id_coverage** – InstantVerify failed and AAMVA passed, but the AAMVA response does not cover the attributes that failed InstantVerify. This is considered a *fail*."
      }
    },
    {
      "height": 9,
      "width": 12,
      "y": 38,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter \n  ispresent(properties.event_properties.proofing_results.context.resolution_adjudication_reason) and\n  properties.event_properties.proofing_results.context.resolution_adjudication_reason = 'fail_resolution_skip_state_id'\n| stats \n  count(*) as count by properties.event_properties.proofing_results.context.stages.state_id.state as `Non-coverage state`\n| sort count desc",
        "region": "${var.region}",
        "stacked": false,
        "title": "Failed resolution with unsupported state",
        "view": "table"
      }
    },
    {
      "height": 13,
      "width": 12,
      "y": 25,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter ispresent(properties.event_properties.proofing_results.context.resolution_adjudication_reason)\n| stats \n  count(*) as `Event count`, avg(properties.event_properties.proofing_results.context.stages.resolution.success) as `Success rate` by properties.event_properties.proofing_results.context.stages.state_id.state as `State`\n| sort `Success rate` asc\n",
        "region": "${var.region}",
        "stacked": false,
        "title": "Instant Verify success rate by state",
        "view": "table"
      }
    },
    {
      "height": 2,
      "width": 24,
      "y": 23,
      "x": 0,
      "type": "text",
      "properties": {
        "markdown": "# State-level metrics"
      }
    },
    {
      "height": 3,
      "width": 24,
      "y": 20,
      "x": 0,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter ispresent(properties.event_properties.proofing_results.context.resolution_adjudication_reason) \n  and properties.event_properties.proofing_results.context.resolution_adjudication_reason = 'state_id_covers_failed_resolution'\n| fields \n  `properties.event_properties.errors.Execute Instant Verify.0.Items.0.ItemStatus` = 'fail' as @Addr1Zip_StateMatch,\n  `properties.event_properties.errors.Execute Instant Verify.0.Items.1.ItemStatus` = 'fail' as @SsnFullNameMatch,\n  `properties.event_properties.errors.Execute Instant Verify.0.Items.2.ItemStatus` = 'fail' as @SsnDeathMatchVerification,\n  `properties.event_properties.errors.Execute Instant Verify.0.Items.3.ItemStatus` = 'fail' as @SSNSSAValid,\n  `properties.event_properties.errors.Execute Instant Verify.0.Items.4.ItemStatus` = 'fail' as @IdentityOccupancyVerified,\n  `properties.event_properties.errors.Execute Instant Verify.0.Items.5.ItemStatus` = 'fail' as @AddrDeliverable,\n  `properties.event_properties.errors.Execute Instant Verify.0.Items.6.ItemStatus` = 'fail' as @AddrNotHighRisk,\n  `properties.event_properties.errors.Execute Instant Verify.0.Items.7.ItemStatus` = 'fail' as @DOBFullVerified,\n  `properties.event_properties.errors.Execute Instant Verify.0.Items.8.ItemStatus` = 'fail' as @DOBYearVerified,\n  `properties.event_properties.errors.Execute Instant Verify.0.Items.9.ItemStatus` = 'fail' as @LexIDDeathMatch\n| stats\n  count(*) as Total,\n  sum(@Addr1Zip_StateMatch) as Addr1Zip_StateMatch,\n  sum(@SsnFullNameMatch) as SsnFullNameMatch,\n  sum(@SsnDeathMatchVerification) as SsnDeathMatchVerification,\n  sum(@SSNSSAValid) as SSNSSAValid,\n  sum(@IdentityOccupancyVerified) as IdentityOccupancyVerified,\n  sum(@AddrDeliverable) as AddrDeliverable,\n  sum(@AddrNotHighRisk) as AddrNotHighRisk,\n  sum(@DOBFullVerified) as DOBFullVerified,\n  sum(@DOBYearVerified) as DOBYearVerified,\n  sum(@LexIDDeathMatch) as LexIDDeathMatch",
        "region": "${var.region}",
        "stacked": false,
        "title": "Successfully overridden checks",
        "view": "table"
      }
    },
    {
      "height": 13,
      "width": 12,
      "y": 25,
      "x": 12,
      "type": "log",
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | fields @timestamp, @message\n| filter ispresent(properties.event_properties.proofing_results.context.resolution_adjudication_reason) and properties.event_properties.proofing_results.context.stages.state_id.vendor_name != 'UnsupportedJurisdiction'\n| stats \n  count(*) as `Event count`, avg(properties.event_properties.proofing_results.context.stages.state_id.success) as `Success rate` by properties.event_properties.proofing_results.context.stages.state_id.state as `State`\n| sort `Success rate` asc\n",
        "region": "${var.region}",
        "stacked": false,
        "title": "AAMVA success rate by state",
        "view": "table"
      }
    }
  ]
}
  EOF
}
