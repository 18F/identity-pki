resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "CloudTrail-Throttling-Errors"

  dashboard_body = <<EOF
{
    "widgets": [
        {
            "height": 15,
            "width": 24,
            "y": 6,
            "x": 0,
            "type": "log",
            "properties": {
                "query": "SOURCE 'CloudTrail/DefaultLogGroup' | filter ispresent(errorCode)\n# Excluded calls from PrismaCloud or NewRelic footprinting\n| filter userIdentity.arn not in [\"arn:aws:sts::${data.aws_caller_identity.current.account_id}:assumed-role${var.NewRelicARNRoleName}\",\"arn:aws:sts::${data.aws_caller_identity.current.account_id}:assumed-role${var.PrismaCloudRoleName}\"]\n| filter @message like /(?i)(LimitExceeded|ThrottlingException)/\n| stats count(*) as errorCount by eventSource,errorCode,eventName,errorMessage,awsRegion,userIdentity.arn\n| sort errorCount desc\n ",
                "region": "${var.region}",
                "stacked": false,
                "title": "Log group: CloudTrail/DefaultLogGroup-TableView",
                "view": "table"
            }
        }
    ]
}
EOF
}
