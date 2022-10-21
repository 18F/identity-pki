resource "aws_cloudwatch_dashboard" "idv_resolution_failed_attributes" {
  dashboard_name = "${var.env_name}-idv-resolution-failed-attributes"

  dashboard_body = <<EOF
    {
  "widgets": [
    {
      "type": "log",
      "x": 0,
      "y": 3,
      "width": 24,
      "height": 11,
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth optional verify_wait submitted' and properties.event_properties.proofing_results.context.stages.resolution.vendor_name = 'lexisnexis:instant_verify'\n| fields concat(\n  properties.event_properties.proofing_results.context.stages.resolution.attributes_requiring_additional_verification.0,\n  properties.event_properties.proofing_results.context.stages.resolution.attributes_requiring_additional_verification.1,\n  properties.event_properties.proofing_results.context.stages.resolution.attributes_requiring_additional_verification.2,\n  properties.event_properties.proofing_results.context.stages.resolution.attributes_requiring_additional_verification.3,\n  properties.event_properties.proofing_results.context.stages.resolution.attributes_requiring_additional_verification.4\n) as @failure_reasons\n| fields @failure_reasons like /address/ as @address_failure,\n  @failure_reasons like /dob/ as @dob_failure,\n  @failure_reasons like /ssn/ as @ssn_failure,\n  @failure_reasons like /dead/ as @death_failure,\n  @failure_reasons like /unknown/ as @unknown_failure\n| stats sum(@address_failure) as address_failure,\n  sum(@dob_failure) as dob_failure,\n  sum(@ssn_failure) as ssn_failure,\n  sum(@death_failure) as death_failure,\n  sum(@unknown_failure) as unknown_failure\n  by bin(1year)",
        "region": "${var.region}",
        "stacked": false,
        "view": "bar",
        "title": "InstantVerify failed attributes"
      }
    },
    {
      "type": "log",
      "x": 0,
      "y": 14,
      "width": 24,
      "height": 11,
      "properties": {
        "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter name = 'IdV: doc auth optional verify_wait submitted' and properties.event_properties.proofing_results.context.stages.state_id.vendor_name = 'aamva:state_id'\n| fields concat(\n  properties.event_properties.proofing_results.context.stages.state_id.verified_attributes.0,\n  properties.event_properties.proofing_results.context.stages.state_id.verified_attributes.1,\n  properties.event_properties.proofing_results.context.stages.state_id.verified_attributes.2,\n  properties.event_properties.proofing_results.context.stages.state_id.verified_attributes.3,\n  properties.event_properties.proofing_results.context.stages.state_id.verified_attributes.4,\n  properties.event_properties.proofing_results.context.stages.state_id.verified_attributes.5\n) as @verified_attributes\n| fields @verified_attributes not like /state_id_number/ as @state_id_number_failure\n| fields @verified_attributes not like /address/ and !@state_id_number_failure as @address_failure,\n  @verified_attributes not like /first_name/ and !@state_id_number_failure as\n@first_name_failure,\n  @verified_attributes not like /last_name/ and !@state_id_number_failure as\n@last_name_failure,\n  @verified_attributes not like /dob/ and !@state_id_number_failure as\n@dob_failure\n| stats sum(@address_failure) as address_failure,\n  sum(@first_name_failure) as first_name_failure,\n  sum(@last_name_failure) as last_name_failure,\n  sum(@dob_failure) as dob_failure,\n  sum(@state_id_number_failure) as state_id_number_failure\n  by bin(1year)",
        "region": "${var.region}",
        "stacked": false,
        "title": "AAMVA failed attributes",
        "view": "bar"
      }
    },
    {
      "type": "text",
      "x": 0,
      "y": 0,
      "width": 24,
      "height": 3,
      "properties": {
        "markdown": "# Identity resolution attribute failures\n\nThis dashboard describes which attributes fail during identity resolution for our 2 vendors.\n\nThe first chart shows the number of individual attribute failures for LexisNexis. The second is the same, but for AAMVA."
      }
    }
  ]
}
  EOF
}
