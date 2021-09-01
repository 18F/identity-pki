resource "aws_cloudwatch_dashboard" "idp_external_service" {
  dashboard_name = "${var.env_name}-idp-external-service"
  dashboard_body = <<EOF
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 24,
            "height": 12,
            "properties": {
                "metrics": [
                    [ { "expression": "SEARCH('{${var.env_name}/idp-external-service,Service} \"faraday-response-time\"', 'p99', 300)", "label": "$${PROP('Dim.Service')}", "id": "e1" } ],
                    [ "${var.env_name}/idp-external-service", "aws-kms-decrypt-response-time", { "label": "KMS Decrypt" } ],
                    [ ".", "aws-kms-encrypt-response-time", { "label": "KMS Encrypt" } ],
                    [ ".", "aws-pinpoint-phone-number-validate-response-time", { "label": "Pinpoint Validate Phone" } ],
                    [ ".", "aws-pinpoint-send-messages-response-time", { "label": "Pinpoint Send SMS" } ],
                    [ ".", "aws-pinpoint-voice-send-voice-message-response-time", { "label": "Pinpoint Send Voice" } ],
                    [ ".", "aws-s3-put-object-response-time", { "label": "S3 Put Object" } ],
                    [ ".", "aws-ses-send-raw-email-response-time", { "label": "SES Send Email" } ],
                    [ ".", "aws-sts-assume-role-response-time", { "label": "STS Assume Role" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "period": 300,
                "stat": "p99",
                "title": "99th Percentile Response Times",
                "yAxis": {
                    "left": {
                        "showUnits": false,
                        "label": "Seconds"
                    },
                    "right": {
                        "label": "",
                        "showUnits": false
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 24,
            "width": 24,
            "height": 12,
            "properties": {
                "metrics": [
                    [ { "expression": "SEARCH('{${var.env_name}/idp-external-service,Service} \"faraday-response-time\"', 'SampleCount', 60)", "label": "$${PROP('Dim.Service')}", "id": "e1" } ],
                    [ "${var.env_name}/idp-external-service", "aws-kms-decrypt-response-time", { "label": "KMS Decrypt", "yAxis": "right" } ],
                    [ ".", "aws-kms-encrypt-response-time", { "label": "KMS Encrypt", "yAxis": "right" } ],
                    [ ".", "aws-pinpoint-phone-number-validate-response-time", { "label": "Pinpoint Validate Phone" } ],
                    [ ".", "aws-pinpoint-send-messages-response-time", { "label": "Pinpoint Send SMS" } ],
                    [ ".", "aws-pinpoint-voice-send-voice-message-response-time", { "label": "Pinpoint Send Voice" } ],
                    [ ".", "aws-s3-put-object-response-time", { "label": "S3 Put Object" } ],
                    [ ".", "aws-ses-send-raw-email-response-time", { "label": "SES Send Email" } ],
                    [ ".", "aws-sts-assume-role-response-time", { "label": "STS Assume Role" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "period": 60,
                "stat": "SampleCount",
                "title": "Request Counts",
                "setPeriodToTimeRange": true,
                "yAxis": {
                    "left": {
                        "showUnits": true
                    }
                },
                "legend": {
                    "position": "bottom"
                }
            }
        },
        {
            "height": 12,
            "width": 12,
            "y": 12,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ { "expression": "SEARCH('{${var.env_name}/idp-external-service,Service} \"faraday-response-time\"', 'p50', 300)", "label": "$${PROP('Dim.Service')}", "id": "e1", "region": "us-west-2" } ],
                    [ "${var.env_name}/idp-external-service", "aws-kms-decrypt-response-time", { "label": "KMS Decrypt" } ],
                    [ ".", "aws-kms-encrypt-response-time", { "label": "KMS Encrypt" } ],
                    [ ".", "aws-pinpoint-phone-number-validate-response-time", { "label": "Pinpoint Validate Phone" } ],
                    [ ".", "aws-pinpoint-send-messages-response-time", { "label": "Pinpoint Send SMS" } ],
                    [ ".", "aws-pinpoint-voice-send-voice-message-response-time", { "label": "Pinpoint Send Voice" } ],
                    [ ".", "aws-s3-put-object-response-time", { "label": "S3 Put Object" } ],
                    [ ".", "aws-ses-send-raw-email-response-time", { "label": "SES Send Email" } ],
                    [ ".", "aws-sts-assume-role-response-time", { "label": "STS Assume Role" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "period": 300,
                "stat": "p50",
                "title": "50th Percentile Response Times",
                "yAxis": {
                    "left": {
                        "showUnits": false,
                        "label": "Seconds"
                    },
                    "right": {
                        "label": "",
                        "showUnits": false
                    }
                }
            }
        },
        {
            "height": 12,
            "width": 12,
            "y": 12,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ { "expression": "SEARCH('{${var.env_name}/idp-external-service,Service} \"faraday-response-time\"', 'p90', 300)", "label": "$${PROP('Dim.Service')}", "id": "e1", "region": "us-west-2" } ],
                    [ "${var.env_name}/idp-external-service", "aws-kms-decrypt-response-time", { "label": "KMS Decrypt" } ],
                    [ ".", "aws-kms-encrypt-response-time", { "label": "KMS Encrypt" } ],
                    [ ".", "aws-pinpoint-phone-number-validate-response-time", { "label": "Pinpoint Validate Phone" } ],
                    [ ".", "aws-pinpoint-send-messages-response-time", { "label": "Pinpoint Send SMS" } ],
                    [ ".", "aws-pinpoint-voice-send-voice-message-response-time", { "label": "Pinpoint Send Voice" } ],
                    [ ".", "aws-s3-put-object-response-time", { "label": "S3 Put Object" } ],
                    [ ".", "aws-ses-send-raw-email-response-time", { "label": "SES Send Email" } ],
                    [ ".", "aws-sts-assume-role-response-time", { "label": "STS Assume Role" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "period": 300,
                "stat": "p90",
                "title": "90th Percentile Response Times",
                "yAxis": {
                    "left": {
                        "showUnits": false,
                        "label": "Seconds"
                    },
                    "right": {
                        "label": "",
                        "showUnits": false
                    }
                }
            }
        }
    ]
}
EOF
}
