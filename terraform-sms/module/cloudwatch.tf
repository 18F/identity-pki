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
                    [ ".", "DirectSendMessageThrottled", "Channel", "SMS", "ApplicationId", "${aws_pinpoint_app.main.application_id}", { "stat": "Sum", "period": 60 } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "Pinpoint metrics: ${aws_pinpoint_app.main.name} ${var.env}",
                "period": 300,
                "liveData": false
            }
        }
    ]
}
EOF
}
