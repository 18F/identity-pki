# main ALB dashboard

variable "enabled" {
    default = 1
}

variable "dashboard_name" {
    description = "Human-visible name of the dashboard"
}

variable "alb_arn_suffix" {
	description = "ARN suffix of the ALB"
}

variable "target_group_label" {
	description = "Human label to explain what the target group servers are"
}

variable "target_group_arn_suffix" {
	description = "ARN suffix of the target group, used for displaying response time"
}

output "dashboard_arn" {
    value = "${aws_cloudwatch_dashboard.alb.dashboard_arn}"
}

resource "aws_cloudwatch_dashboard" "alb" {
    count = "${var.enabled}"
    dashboard_name = "${var.dashboard_name}"
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
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", "${var.alb_arn_suffix}", { "stat": "Sum", "period": 60 } ],
                    [ ".", "HTTPCode_Target_3XX_Count", ".", ".", { "stat": "Sum", "period": 60 } ],
                    [ ".", "HTTPCode_Target_2XX_Count", ".", ".", { "stat": "Sum", "period": 60 } ],
                    [ ".", "HTTPCode_Target_5XX_Count", ".", ".", { "stat": "Sum", "period": 60 } ]
                ],
                "region": "us-west-2",
                "title": "Target HTTP response codes from ${var.target_group_label}",
                "period": 300
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 9,
            "width": 24,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${var.alb_arn_suffix}", { "stat": "Sum", "period": 60 } ]
                ],
                "region": "us-west-2",
                "title": "Request volume",
                "period": 300,
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 15,
            "width": 24,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", "${var.alb_arn_suffix}", { "period": 60, "stat": "Sum", "color": "#d62728" } ]
                ],
                "region": "us-west-2",
                "title": "5XX errors from ALB",
                "period": 300,
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 21,
            "width": 24,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/ApplicationELB", "TargetResponseTime", "TargetGroup", "${var.target_group_arn_suffix}", "LoadBalancer", "${var.alb_arn_suffix}", { "stat": "Average" } ]
                ],
                "region": "us-west-2",
                "title": "Target avg response time",
                "period": 300,
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                }
            }
        }
    ]
}
EOF
}
