resource "aws_cloudwatch_dashboard" "idp_id_token_hint_tracker" {
  dashboard_name = "${var.env_name}-idp-idp_id_token_hint_tracker"
  dashboard_body = <<EOF
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 24,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "${var.env_name}/SpillDetectorMetrics", "id_token_hint-use" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "title": "id_token_hint Use",
                "period": 60,
                "stat": "Sum",
                "yAxis": {
                    "left": {
                        "showUnits": false
                    },
                    "right": {
                        "showUnits": false
                    }
                }
            }
        },
        {
            "type": "log",
            "x": 0,
            "y": 6,
            "width": 24,
            "height": 6,
            "properties": {
                "query": "SOURCE '${var.env_name}_/srv/idp/shared/log/production.log' | ## Count use of id_token_hint in RP-Initiated logout by post_logout_redirect_uri value\n## Remove this query after all SPs have converted to use of client_id\nfilter path like \"/openid_connect/logout\" and path like \"id_token_hint\" | parse path /id_token_hint=.+?\\\\.(?<payload>.*?)\\\\./\n| parse path /post_logout_redirect_uri=https(:\\\\/\\\\/|%3A%2F%2F)(?<redirect_fqdn>.+?)(\\\\/|%2F)/\n| stats count() as count by redirect_fqdn\n| sort count desc",
                "region": "us-west-2",
                "stacked": false,
                "view": "table",
                "title": "id_token_hint Use by post_logout_redirect_uri"
            }
        }
    ]
}
EOF
}

