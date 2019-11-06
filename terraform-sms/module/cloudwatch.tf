# Pinpoint SMS dashboard

resource "aws_cloudwatch_dashboard" "pinpoint" {

    # The dashboard naemd "CloudWatch-Default" gets displayed on the CloudWatch
    # front page for the account. Since there's nothing else in this account, a
    # graph of Pinpoint traffic is a good one.
    dashboard_name = "CloudWatch-Default"

    dashboard_body = <<EOF
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 24,
            "height": 9,
            "properties": {
                "metrics": [
                    [ "AWS/Pinpoint", "TotalEvents", "ApplicationId", "${aws_pinpoint_app.main.application_id}", { "stat": "Sum", "period": 60 } ],
                    [ ".", "DirectSendMessageTemporaryFailure", "Channel", "SMS", "ApplicationId", "${aws_pinpoint_app.main.application_id}", { "period": 60, "stat": "Sum" } ],
                    [ ".", "DirectSendMessageThrottled", ".", ".", ".", ".", { "period": 60, "stat": "Sum" } ],
                    [ ".", "DirectSendMessagePermanentFailure", ".", ".", ".", ".", { "period": 60, "stat": "Sum" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "Pinpoint metrics: ${aws_pinpoint_app.main.name} ${var.env}",
                "period": 300,
                "liveData": false
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 24,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/SNS", "SMSMonthToDateSpentUSD", { "id": "m1", "period": 86400, "stat": "Maximum", "visible": false } ],
                    [ { "expression": "RATE(m1) * 3600 * 24", "label": "Daily SMS Spend Rate USD", "id": "e1", "color": "#2ca02c" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "Pinpoint spending: ${aws_pinpoint_app.main.name} ${var.env}",
                "period": 300,
                "liveData": false,
                "yAxis": {
                    "left": {
                        "label": "USD",
                        "min": 0,
                        "showUnits": false
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 24,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/SNS", "SMSMonthToDateSpentUSD", { "period": 86400, "stat": "Maximum" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "Pinpoint spending: ${aws_pinpoint_app.main.name} ${var.env}",
                "period": 300,
                "liveData": false,
                "yAxis": {
                    "left": {
                        "label": "USD",
                        "min": 0,
                        "showUnits": false
                    }
                },
                "annotations": {
                    "horizontal": [
                        {
                            "label": "Monthly spend limit",
                            "value": ${var.pinpoint_spend_limit}
                        }
                    ]
                }
            }
        }
    ]
}
EOF
}
