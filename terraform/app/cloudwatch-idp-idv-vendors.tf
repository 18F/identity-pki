module "dashboard-idp-idv-vendors" {
  source = "../modules/cloudwatch_dashboard"

  dashboard_name = "${var.env_name}-idp-idv-vendors"

  # Uncomment this to add an "SP" filter to the dashboard.
  # For this to work, you need to add the following filter to _all_ relevant queries in your dashboard:
  #
  #   | filter ispresent(properties.service_provider) or not ispresent(properties.service_provider)
  #
  filter_sps = var.idp_dashboard_filter_sps

  # dashboard_definition contains the JSON exported from Amazon Cloudwatch via bin/copy-cloudwatch-dashboard.
  # If you make changes to your dashboard, just re-run this command:
  #
  #   aws-vault exec prod-power -- bin/copy-cloudwatch-dashboard --in prod-idp-idv-vendors --out cloudwatch-idp-idv-vendors.tf
  #
  # Then commit your changes back to this repository.
  #
  dashboard_definition = {
    "widgets" : [
      {
        "height" : 6,
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter ispresent(properties.service_provider) or not ispresent(properties.service_provider) | fields @timestamp, @message\n| filter name in [\n    'IdV: doc auth verify proofing results',\n    'IdV: doc auth image upload vendor submitted',\n    'IdV: doc auth send_link submitted'\n    ]\n| fields\n    # AAMVA\n    (\n        name = 'IdV: doc auth verify proofing results' \n        and\n        properties.event_properties.proofing_results.context.stages.state_id.vendor_name = 'aamva:state_id'\n    ) as is_aamva_request,\n    (\n        is_aamva_request\n        and\n        ispresent(properties.event_properties.proofing_results.context.stages.state_id.exception)\n    ) as is_aamva_exception,\n    # Acuant\n    (\n        name = 'IdV: doc auth image upload vendor submitted'\n        and\n        properties.event_properties.vendor = 'Acuant'\n    ) as is_acuant_request,\n    (\n        is_acuant_request\n        and\n        ispresent(properties.event_properties.exception)\n        and\n        properties.event_properties.exception not in [\n            # 438 = \"Document image load failure\"\n            'DocAuth::Acuant::Requests::UploadImageRequest Unexpected HTTP response 438',\n            # 439 = \"Invalid or unsupported document image pixel depth.\"\n            'DocAuth::Acuant::Requests::UploadImageRequest Unexpected HTTP response 439',\n            # 440: \"Document image size is outside the acceptable range.\"\n            'DocAuth::Acuant::Requests::UploadImageRequest Unexpected HTTP response 440',\n            # 441: \"Document image resolution is outside the acceptable range.\"\n            'DocAuth::Acuant::Requests::UploadImageRequest Unexpected HTTP response 441',\n            # 442: \"Document image resolution difference between each axis is outside the acceptable range.\"\n            'DocAuth::Acuant::Requests::UploadImageRequest Unexpected HTTP response 442'\n        ]\n    ) as is_acuant_exception,\n    # InstantVerify\n    (\n        name = 'IdV: doc auth verify proofing results'\n        and\n        properties.event_properties.proofing_results.context.stages.resolution.vendor_name = 'lexisnexis:instant_verify'\n    ) as is_instant_verify_request,\n    (\n        is_instant_verify_request\n        and\n        ispresent(properties.event_properties.proofing_results.context.stages.resolution.exception)\n    ) as is_instant_verify_exception,\n    # Pinpoint SMS\n    (\n        name = 'IdV: doc auth send_link submitted'\n        and\n        ispresent(properties.event_properties.telephony_response.delivery_status)\n    ) as is_pinpoint_sms_request,\n    (\n        is_pinpoint_sms_request\n        and\n        ispresent(properties.event_properties.telephony_response.error)\n        and properties.event_properties.telephony_response.error not in [\n            'Pinpoint Error: PERMANENT_FAILURE - 400'\n        ]        \n    ) as is_pinpoint_sms_exception,\n    # LexisNexis TrueID\n    (\n        name = 'IdV: doc auth image upload vendor submitted'\n        and\n        properties.event_properties.vendor = 'TrueID'\n    ) as is_trueid_request,\n    (\n        is_trueid_request\n        and\n        ispresent(properties.event_properties.exception)\n    ) as is_trueid_exception\n| stats sum(is_aamva_exception) / sum(is_aamva_request) as AAMVA, sum(is_acuant_exception) / sum(is_acuant_request) as Acuant, sum(is_instant_verify_exception) / sum(is_instant_verify_request) as InstantVerify, sum(is_pinpoint_sms_exception) / sum(is_pinpoint_sms_request) as Pinpoint_SMS, sum(is_trueid_exception) / sum(is_trueid_request) as TrueID by bin(1h)",
          "region" : var.region,
          "stacked" : false,
          "title" : "DocAuth vendor error rates (lower is better)",
          "view" : "timeSeries"
        },
        "type" : "log",
        "width" : 12,
        "x" : 12,
        "y" : 4
      },
      {
        "height" : 2,
        "properties" : {
          "markdown" : "# ![Login.gov](https://login.gov/assets/img/logo.svg) IdV Monitoring Dashboard\n\n\nThis dashboard can be used to monitor requests made to vendors during the identity verification (IdV) flow."
        },
        "type" : "text",
        "width" : 24,
        "x" : 0,
        "y" : 0
      },
      {
        "height" : 2,
        "properties" : {
          "markdown" : "## DocAuth\nDocument scanning and PII extraction services.\nNote: AWS Pinpoint is used here for the \"hybrid\" document upload path (use your phone to upload)."
        },
        "type" : "text",
        "width" : 24,
        "x" : 0,
        "y" : 2
      },
      {
        "height" : 6,
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter ispresent(properties.service_provider) or not ispresent(properties.service_provider) | fields @timestamp, @message\n| filter name in [\n    'IdV: doc auth verify proofing results',\n    'IdV: doc auth image upload vendor submitted',\n    'IdV: doc auth send_link submitted'\n    ]\n| fields\n    # AAMVA\n    (\n        name = 'IdV: doc auth verify proofing results' \n        and\n        properties.event_properties.proofing_results.context.stages.state_id.vendor_name = 'aamva:state_id'\n    ) as is_aamva_request,\n    # Acuant\n    (\n        name = 'IdV: doc auth image upload vendor submitted'\n        and\n        properties.event_properties.vendor = 'Acuant'\n    ) as is_acuant_request,\n    # InstantVerify\n    (\n        name = 'IdV: doc auth verify proofing results'\n        and\n        properties.event_properties.proofing_results.context.stages.resolution.vendor_name = 'lexisnexis:instant_verify'\n    ) as is_instant_verify_request,\n    # LexisNexis TrueID\n    (\n        name = 'IdV: doc auth image upload vendor submitted'\n        and\n        properties.event_properties.vendor = 'TrueID'\n    ) as is_trueid_request,\n    # Pinpoint SMS\n    (\n        name = 'IdV: doc auth send_link submitted'\n        and\n        ispresent(properties.event_properties.telephony_response.delivery_status)\n    ) as is_pinpoint_sms_request\n| stats sum(is_aamva_request) as AAMVA, sum(is_acuant_request) as Acuant, sum(is_instant_verify_request) as InstantVerify, sum(is_pinpoint_sms_request) as Pinpoint_SMS, sum(is_trueid_request) as TrueID by bin(1h)",
          "region" : var.region,
          "stacked" : false,
          "title" : "DocAuth vendor request counts",
          "view" : "timeSeries"
        },
        "type" : "log",
        "width" : 12,
        "x" : 0,
        "y" : 4
      },
      {
        "height" : 2,
        "properties" : {
          "markdown" : "## Address / phone verification\n\nServices used to verify users have access to the phone numbers they provide."
        },
        "type" : "text",
        "width" : 24,
        "x" : 0,
        "y" : 16
      },
      {
        "height" : 6,
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter ispresent(properties.service_provider) or not ispresent(properties.service_provider) | fields @timestamp, @message\n| filter name in [\n   'IdV: phone confirmation vendor',\n   'IdV: phone confirmation otp sent'\n]\n| fields\n    # AWS PinPoint (SMS)\n    (\n        name = 'IdV: phone confirmation otp sent' \n        and \n        properties.event_properties.adapter = 'pinpoint'\n        and \n        properties.event_properties.otp_delivery_preference = 'sms'\n    ) as is_pinpoint_sms_request,\n    (\n        is_pinpoint_sms_request\n        and\n        ispresent(properties.event_properties.telephony_response.error)\n        and properties.event_properties.telephony_response.error not in [\n            'Pinpoint Error: PERMANENT_FAILURE - 400'\n        ]\n    ) as is_pointpoint_sms_exception,\n    # AWS PinPoint (Voice)\n    (\n        name = 'IdV: phone confirmation otp sent' \n        and \n        properties.event_properties.adapter = 'pinpoint'\n        and \n        properties.event_properties.otp_delivery_preference = 'voice'\n    ) as is_pinpoint_voice_request,\n    (\n        is_pinpoint_voice_request\n        and\n        ispresent(properties.event_properties.telephony_response.error)\n        and properties.event_properties.telephony_response.error not in [\n            'Pinpoint Error: PERMANENT_FAILURE - 400'\n        ]\n    ) as is_pointpoint_voice_exception,\n    # PhoneFinder\n    (\n        name = 'IdV: phone confirmation vendor'\n        and\n        properties.event_properties.vendor.vendor_name\t= 'lexisnexis:phone_finder'\n    ) as is_phone_finder_request,\n    (\n        is_phone_finder_request\n        and\n        ispresent(properties.event_properties.vendor.exception)\n    ) as is_phone_finder_exception\n| stats sum(is_pointpoint_sms_exception) / sum(is_pinpoint_sms_request) as Pinpoint_SMS, sum(is_pointpoint_voice_exception) / sum(is_pinpoint_voice_request) as Pinpoint_Voice, sum(is_phone_finder_exception) / sum(is_phone_finder_request) as PhoneFinder by bin(1h)",
          "region" : var.region,
          "stacked" : false,
          "title" : "Address / phone verification vendor error rates (lower is better)",
          "view" : "timeSeries"
        },
        "type" : "log",
        "width" : 12,
        "x" : 12,
        "y" : 18
      },
      {
        "height" : 6,
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter ispresent(properties.service_provider) or not ispresent(properties.service_provider) | fields @timestamp, @message\n| filter name in [\n   'IdV: phone confirmation vendor',\n   'IdV: phone confirmation otp sent'\n]\n| fields\n    # AWS PinPoint (SMS)\n    (\n        name = 'IdV: phone confirmation otp sent' \n        and \n        properties.event_properties.adapter = 'pinpoint'\n        and \n        properties.event_properties.otp_delivery_preference = 'sms'\n    ) as is_pinpoint_sms_request,\n    # AWS PinPoint (Voice)\n    (\n        name = 'IdV: phone confirmation otp sent' \n        and \n        properties.event_properties.adapter = 'pinpoint'\n        and \n        properties.event_properties.otp_delivery_preference = 'voice'\n    ) as is_pinpoint_voice_request,\n    # PhoneFinder\n    (\n        name = 'IdV: phone confirmation vendor'\n        and\n        properties.event_properties.vendor.vendor_name\t= 'lexisnexis:phone_finder'\n    ) as is_phone_finder_request\n| stats sum(is_pinpoint_sms_request) as Pinpoint_SMS, sum(is_pinpoint_voice_request) as Pinpoint_Voice, sum(is_phone_finder_request) as PhoneFinder by bin(1h)",
          "region" : var.region,
          "stacked" : false,
          "title" : "Address / phone verification vendor request counts",
          "view" : "timeSeries"
        },
        "type" : "log",
        "width" : 12,
        "x" : 0,
        "y" : 18
      },
      {
        "height" : 2,
        "properties" : {
          "markdown" : "## Fraud prevention\n\nServices used to prevent fraudulent use of IdV."
        },
        "type" : "text",
        "width" : 24,
        "x" : 0,
        "y" : 24
      },
      {
        "height" : 5,
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter ispresent(properties.service_provider) or not ispresent(properties.service_provider) | fields @timestamp, @message\n| filter name in [\n   'IdV: doc auth verify proofing results'\n]\n| fields\n    # LexisNexis ThreatMetrix\n    (\n        name = 'IdV: doc auth verify proofing results'\n        and\n        properties.event_properties.proofing_results.context.stages.threatmetrix.client\n = 'lexisnexis'\n    ) as is_threatmetrix_request\n| stats sum(is_threatmetrix_request) as ThreatMetrix by bin(1h)",
          "region" : var.region,
          "stacked" : false,
          "title" : "Fraud prevention vendor request counts",
          "view" : "timeSeries"
        },
        "type" : "log",
        "width" : 12,
        "x" : 0,
        "y" : 26
      },
      {
        "height" : 5,
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter ispresent(properties.service_provider) or not ispresent(properties.service_provider) | fields @timestamp, @message\n| filter name in [\n   'IdV: doc auth verify proofing results'\n]\n| fields\n    # LexisNexis ThreatMetrix\n    (\n        name = 'IdV: doc auth verify proofing results'\n        and\n        properties.event_properties.proofing_results.context.stages.threatmetrix.client\n = 'lexisnexis'\n    ) as is_threatmetrix_request,\n    (\n        is_threatmetrix_request\n        and\n        ispresent(properties.event_properties.proofing_results.context.stages.threatmetrix.exception)\n    ) as is_threatmetrix_exception\n| stats sum(is_threatmetrix_exception) / sum(is_threatmetrix_request) as ThreatMetrix by bin(1h)",
          "region" : var.region,
          "stacked" : false,
          "title" : "Fraud prevention vendor error rates (lower is better)",
          "view" : "timeSeries"
        },
        "type" : "log",
        "width" : 12,
        "x" : 12,
        "y" : 26
      },
      {
        "height" : 6,
        "properties" : {
          "query" : "SOURCE '${var.env_name}_/srv/idp/shared/log/events.log' | filter ispresent(properties.service_provider) or not ispresent(properties.service_provider) | fields @timestamp, @message\n| filter\n    # AAMVA\n    (\n        name = 'IdV: doc auth verify proofing results' \n        and\n        properties.event_properties.proofing_results.context.stages.state_id.vendor_name = 'aamva:state_id'\n        and\n        ispresent(properties.event_properties.proofing_results.context.stages.state_id.exception)\n    )\n    or\n    # Acuant\n    (\n        name = 'IdV: doc auth image upload vendor submitted'\n        and\n        properties.event_properties.vendor = 'Acuant'\n        and\n        ispresent(properties.event_properties.exception)\n        and\n        properties.event_properties.exception not in [\n            # 438 = \"Document image load failure\"\n            'DocAuth::Acuant::Requests::UploadImageRequest Unexpected HTTP response 438',\n            # 439 = \"Invalid or unsupported document image pixel depth.\"\n            'DocAuth::Acuant::Requests::UploadImageRequest Unexpected HTTP response 439',\n            # 440: \"Document image size is outside the acceptable range.\"\n            'DocAuth::Acuant::Requests::UploadImageRequest Unexpected HTTP response 440',\n            # 441: \"Document image resolution is outside the acceptable range.\"\n            'DocAuth::Acuant::Requests::UploadImageRequest Unexpected HTTP response 441',\n            # 442: \"Document image resolution difference between each axis is outside the acceptable range.\"\n            'DocAuth::Acuant::Requests::UploadImageRequest Unexpected HTTP response 442'\n        ]\n    )\n    or\n    # InstantVerify\n    (\n        name = 'IdV: doc auth verify proofing results'\n        and\n        properties.event_properties.proofing_results.context.stages.resolution.vendor_name = 'lexisnexis:instant_verify'\n        and\n        ispresent(properties.event_properties.proofing_results.context.stages.resolution.exception)\n    )\n    or\n    # LexisNexis TrueID\n    (\n        name = 'IdV: doc auth image upload vendor submitted'\n        and\n        properties.event_properties.vendor = 'TrueID'\n        and\n        ispresent(properties.event_properties.exception)\n    )\n| fields\n    replace(concat(\n        # AAMVA\n        replace(\n            name = 'IdV: doc auth verify proofing results' \n            and\n            properties.event_properties.proofing_results.context.stages.state_id.vendor_name = 'aamva:state_id'\n            and\n            ispresent(properties.event_properties.proofing_results.context.stages.state_id.exception),\n            '1',\n            'AAMVA'\n        ),\n        # Acuant\n        replace(\n            name = 'IdV: doc auth image upload vendor submitted'\n            and\n            properties.event_properties.vendor = 'Acuant'\n            and\n            ispresent(properties.event_properties.exception)\n            and\n            properties.event_properties.exception not in [\n                # 438 = \"Document image load failure\"\n                'DocAuth::Acuant::Requests::UploadImageRequest Unexpected HTTP response 438',\n                # 439 = \"Invalid or unsupported document image pixel depth.\"\n                'DocAuth::Acuant::Requests::UploadImageRequest Unexpected HTTP response 439',\n                # 440: \"Document image size is outside the acceptable range.\"\n                'DocAuth::Acuant::Requests::UploadImageRequest Unexpected HTTP response 440',\n                # 441: \"Document image resolution is outside the acceptable range.\"\n                'DocAuth::Acuant::Requests::UploadImageRequest Unexpected HTTP response 441',\n                # 442: \"Document image resolution difference between each axis is outside the acceptable range.\"\n                'DocAuth::Acuant::Requests::UploadImageRequest Unexpected HTTP response 442'\n            ],\n            '1',\n            'Acuant'\n        ),\n        # InstantVerify\n        replace(\n            name = 'IdV: doc auth verify proofing results'\n            and\n            properties.event_properties.proofing_results.context.stages.resolution.vendor_name = 'lexisnexis:instant_verify'            and\n            ispresent(properties.event_properties.proofing_results.context.stages.resolution.exception),\n            '1',\n            'LexisNexis InstantVerify'\n        ),\n        # TrueID\n        replace(\n            name = 'IdV: doc auth image upload vendor submitted'\n            and\n            properties.event_properties.vendor = 'TrueID'\n            and\n            ispresent(properties.event_properties.exception),\n            '1',\n            'LexisNexis TrueID'\n        )\n    ), '0', '') as vendor,\n    coalesce(\n        properties.event_properties.proofing_results.context.stages.state_id.state\n    ) as state,\n    coalesce(\n        properties.event_properties.exception,\n        properties.event_properties.proofing_results.context.stages.state_id.exception,\n        properties.event_properties.proofing_results.context.stages.resolution.exception\n    ) as error_message\n| stats count(*) as count by vendor, error_message, state\n| sort count desc\n",
          "region" : var.region,
          "stacked" : false,
          "title" : "DocAuth vendor errors",
          "view" : "table"
        },
        "type" : "log",
        "width" : 24,
        "x" : 0,
        "y" : 10
      }
    ]
  }
}