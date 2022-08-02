resource "aws_cloudwatch_dashboard" "idp_workload" {
  dashboard_name = "${var.env_name}-idp-workload"
  dashboard_body = <<EOF
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 8,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", "${aws_alb.idp.arn_suffix}", { "color": "#2ca02c", "label": "2XX" } ],
                    [ ".", "HTTPCode_Target_3XX_Count", ".", ".", { "label": "3XX" } ],
                    [ ".", "HTTPCode_Target_4XX_Count", ".", ".", { "color": "#1f77b4", "label": "4XX" } ],
                    [ ".", "HTTPCode_Target_5XX_Count", ".", ".", { "label": "5XX" } ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "region": "${var.region}",
                "title": "${var.env_name} IdP - Backend Request Status by Code",
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "showUnits": false,
                        "label": "Requests (stacked)"
                    }
                },
                "stat": "Sum"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 20,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/ApplicationELB", "TargetResponseTime", "TargetGroup", "${aws_alb_target_group.idp-ssl.arn_suffix}", "LoadBalancer", "${aws_alb.idp.arn_suffix}", { "stat": "p90", "label": "p90" } ],
                    [ "...", { "label": "p99" } ],
                    [ "...", { "stat": "Maximum", "visible": false } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "${var.env_name} IdP - Backend Request Response Time",
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "label": "Latency (seconds)",
                        "showUnits": false
                    },
                    "right": {
                        "showUnits": false
                    }
                },
                "annotations": {
                    "horizontal": [
                        {
                            "visible": false,
                            "color": "#d68181",
                            "value": 1
                        }
                    ],
                    "vertical": [
                        {
                            "color": "#666",
                            "label": "CBP TTP Launch",
                            "value": "2017-10-01T16:00:00.000Z"
                        },
                        {
                            "color": "#666",
                            "label": "USAJobs Launch",
                            "value": "2018-02-25T15:00:00.000Z"
                        }
                    ]
                },
                "stat": "p99"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 20,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "${aws_autoscaling_group.idp.name}", { "label": "IdP Instances" } ],
                    [ "...", "${aws_autoscaling_group.worker.name}", { "label": "Worker Instances" } ],
                    [ "AWS/RDS", ".", "DBInstanceIdentifier", "${aws_db_instance.idp.id}", { "label": "Database" } ],
                    [ "AWS/ElastiCache", ".", "CacheClusterId", "${var.env_name}-idp-001", { "label": "Cache (1)" } ],
                    [ "...", "${var.env_name}-idp-002", { "label": "Cache (2)" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "${var.env_name} IdP - CPU Utilization",
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "label": "% Utilization (max)",
                        "showUnits": false
                    }
                },
                "stat": "Maximum",
                "annotations": {
                    "horizontal": [
                        {
                            "label": "CPU Autoscaling Threshold",
                            "value": 40
                        }
                    ]
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 14,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ { "expression": "(target_errs + elb_5xx) / (elb_3xx + elb_4xx + elb_5xx + target_total) * 100", "label": "Overall Error Rate", "id": "err_rate", "color": "#9467bd", "visible": false, "region": "${var.region}" } ],
                    [ { "expression": "elb_5xx / (elb_3xx + elb_4xx + elb_5xx + target_total) * 100", "label": "Load Balancer Frontend", "id": "elb_err_rate", "color": "#000", "region": "${var.region}" } ],
                    [ { "expression": "(target_errs / target_total) * 100", "label": "Webserver Backend", "id": "target_err_rate", "color": "#d62728", "period": 60, "stat": "Sum", "region": "${var.region}" } ],
                    [ "AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${aws_alb.idp.arn_suffix}", { "id": "target_total", "label": "Backend RequestCount", "color": "#1f77b4", "yAxis": "right", "visible": false } ],
                    [ ".", "HTTPCode_Target_5XX_Count", ".", ".", { "id": "target_errs", "yAxis": "right", "visible": false, "color": "#ffbb78" } ],
                    [ ".", "HTTPCode_ELB_3XX_Count", ".", ".", { "id": "elb_3xx", "yAxis": "right", "visible": false, "color": "#c49c94" } ],
                    [ ".", "HTTPCode_ELB_4XX_Count", ".", ".", { "id": "elb_4xx", "yAxis": "right", "visible": false, "color": "#bcbd22" } ],
                    [ ".", "HTTPCode_ELB_5XX_Count", ".", ".", { "id": "elb_5xx", "yAxis": "right", "visible": false, "color": "#c5b0d5" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "yAxis": {
                    "left": {
                        "label": "Error %",
                        "showUnits": false,
                        "min": 0
                    }
                },
                "title": "${var.env_name} IdP - HTTP Error Rate",
                "period": 60,
                "annotations": {
                    "horizontal": [
                        {
                            "color": "#ffbb80",
                            "label": "Warning",
                            "value": 1
                        },
                        {
                            "color": "#d68181",
                            "label": "Alarm",
                            "value": 5
                        }
                    ]
                },
                "legend": {
                    "position": "bottom"
                },
                "stat": "Sum"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 32,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "${aws_db_instance.idp.id}", { "label": "Database" } ],
                    [ "AWS/ElastiCache", "CurrConnections", "CacheClusterId", "${var.env_name}-idp-001", { "label": "Cache (1)" } ],
                    [ "...", "${var.env_name}-idp-002", { "label": "Cache (2)" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "${var.env_name} IdP - Datastore Connections",
                "stat": "Maximum",
                "period": 60,
                "yAxis": {
                    "left": {
                        "label": "Connections (max)",
                        "showUnits": false
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 26,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "WriteIOPS", "DBInstanceIdentifier", "${aws_db_instance.idp.id}", { "label": "Write" } ],
                    [ ".", "ReadIOPS", ".", ".", { "label": "Read" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "title": "${var.env_name} IdP - Database IOPS",
                "region": "${var.region}",
                "period": 60,
                "stat": "Maximum",
                "yAxis": {
                    "left": {
                        "label": "IOPS (max)",
                        "showUnits": false
                    },
                    "right": {
                        "showUnits": false
                    }
                },
                "annotations": {
                    "horizontal": [
                        {
                            "label": "Provisioned IOPS",
                            "value": ${var.rds_iops_idp},
                            "fill": "above"
                        }
                    ]
                }
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 14,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/SES", "Send", { "label": "Global SES Send [sum: $${SUM}]" } ],
                    [ ".", "Delivery", { "label": "Global SES Delivery [sum: $${SUM}]" } ],
                    [ ".", "Bounce", { "label": "Global SES Bounce [sum: $${SUM}]" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "stat": "Sum",
                "period": 60,
                "title": "IdP - Combined Account Email",
                "yAxis": {
                    "left": {
                        "label": "Events",
                        "showUnits": false
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 2,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "${var.env_name}/idp-authentication", "sp-redirect-initiated-all", { "label": "sp-return [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "user-marked-authenticated", { "label": "authenticated [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "user-registration-complete", { "label": "registration-complete [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "rate-limit-triggered", { "label": "rate-limited [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "login-failure-email-or-password", { "label": "fail-email-pass [sum:$${SUM}, max:$${MAX}]" } ],
                    [ "${var.env_name}/idp-ialx", "idv-review-complete-success", { "label": "idv-review-complete-success [sum:$${SUM}, max:$${MAX}]" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "stat": "Sum",
                "period": 60,
                "title": "${var.env_name} IdP - Authentication Events",
                "yAxis": {
                    "left": {
                        "label": "Events",
                        "showUnits": false
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 38,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/Usage", "CallCount", "Type", "API", "Resource", "CryptographicOperationsSymmetric", "Service", "KMS", "Class", "None", { "visible": false } ],
                    [ "...", "DescribeCustomKeyStores", ".", ".", ".", ".", { "visible": false } ],
                    [ "...", "ListAliases", ".", ".", ".", ".", { "visible": false } ],
                    [ "...", "GetKeyRotationStatus", ".", ".", ".", ".", { "visible": false } ],
                    [ "...", "DescribeKey", ".", ".", ".", ".", { "visible": false } ],
                    [ "...", "ListKeys", ".", ".", ".", ".", { "visible": false } ],
                    [ "...", "GetKeyPolicy", ".", ".", ".", ".", { "visible": false } ],
                    [ "...", "ListResourceTags", ".", ".", ".", ".", { "visible": false } ],
                    [ "...", "CreateGrant", ".", ".", ".", ".", { "visible": false } ],
                    [ "${var.env_name}/idp-authentication", "kms-encrypt-session", { "label": "kms-encrypt-session" } ],
                    [ ".", "kms-decrypt-session", { "label": "kms-decrypt-session" } ],
                    [ ".", "kms-encrypt-password-digest", { "label": "kms-encrypt-password-digest" } ],
                    [ ".", "kms-decrypt-password-digest", { "label": "kms-decrypt-password-digest" } ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "region": "${var.region}",
                "stat": "Sum",
                "period": 60,
                "title": "${var.env_name} IdP - KMS Symmetric Encryption Events",
                "yAxis": {
                    "left": {
                        "label": "Events",
                        "showUnits": false
                    }
                }
            }
        },
        {
            "type": "text",
            "x": 0,
            "y": 0,
            "width": 24,
            "height": 2,
            "properties": {
                "markdown": "\n# ${var.env_name} Workload\n\nNote that \"Events\" values are displayed in units of __events / interval__ where __interval__ changes as you zoom out.  Use __Actions -> Period__ and set to 1 minute to see consistent units.\n"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 8,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "${var.env_name}/idp-authentication", "pinpoint-telephony-sms-sent", { "label": "[sum: $${SUM}] pinpoint-telephony-sms-sent" } ],
                    [ ".", "pinpoint-telephony-sms-failed-throttled", { "label": "[sum: $${SUM}] pinpoint-telephony-sms-failed-throttled" } ],
                    [ ".", "pinpoint-telephony-sms-failed-other", { "label": "[sum: $${SUM}] pinpoint-telephony-sms-failed-other" } ],
                    [ ".", "pinpoint-telephony-voice-sent", { "label": "[sum: $${SUM}] pinpoint-telephony-voice-sent" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "stat": "Sum",
                "period": 60,
                "title": "${var.env_name} - Telephony Detail",
                "yAxis": {
                    "left": {
                        "label": "Events",
                        "showUnits": false
                    }
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 2,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "${var.env_name}/idp-authentication", "remembered-device-used-for-authentication", { "label": "Remembered Device [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "login-mfa-success", "multi_factor_auth_method", "backup_code", { "label": "Backup Code Success [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "login-mfa-failure", ".", ".", { "label": "Backup Code Failure [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "login-mfa-success", ".", "personal-key", { "label": "Personal Key Success [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "login-mfa-failure", ".", ".", { "label": "Personal Key Failure [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "login-mfa-success", ".", "piv_cac", { "label": "PIV/CAC Success [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "login-mfa-failure", ".", ".", { "label": "PIV/CAC Failure [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "login-mfa-success", ".", "sms", { "label": "SMS Success [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "login-mfa-failure", ".", ".", { "label": "SMS Failure [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "login-mfa-success", ".", "totp", { "label": "TOTP Success [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "login-mfa-failure", ".", ".", { "label": "TOTP Failure [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "login-mfa-success", ".", "voice", { "label": "Voice Success [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "login-mfa-failure", ".", ".", { "label": "Voice Failure [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "login-mfa-success", ".", "webauthn_platform", { "label": "WebAuthn Platform Success [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "login-mfa-failure", ".", ".", { "label": "WebAuthn Platform Failure [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "login-mfa-success", ".", "webauthn", { "label": "WebAuthn Roaming Success [sum:$${SUM}, max:$${MAX}]" } ],
                    [ ".", "login-mfa-failure", ".", ".", { "label": "WebAuthn Roaming Failure [sum:$${SUM}, max:$${MAX}]" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "stat": "Sum",
                "period": 60,
                "title": "${var.env_name} - MFA Detail",
                "yAxis": {
                    "left": {
                        "label": "Events",
                        "showUnits": false
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 44,
            "width": 12,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "stat": "Sum",
                "period": 60,
                "title": "${var.env_name} - Proxy Requests",
                "metrics": [
                    [ "LogMetrics/squid", "${var.env_name}/DeniedRequests" ],
                    [ ".", "${var.env_name}/TotalRequests" ]
                ],
                "yAxis": {
                    "left": {
                        "showUnits": false,
                        "label": "Requests"
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 26,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", "${aws_autoscaling_group.idp.name}", { "color": "#2ca02c", "label": "InService" } ],
                    [ ".", "GroupTerminatingInstances", ".", ".", { "color": "#d62728", "label": "Terminating" } ],
                    [ ".", "GroupPendingInstances", ".", ".", { "color": "#ff7f0e", "label": "Pending" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "label": "Count (max)",
                        "showUnits": false
                    }
                },
                "title": "${var.env_name} IdP - Autoscaling Group Instance State",
                "period": 60,
                "stat": "Average",
                "annotations": {
                    "horizontal": [
                        {
                            "label": "Minimum",
                            "value": ${var.asg_idp_min}
                        }
                    ]
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 38,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                   [ "AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", "${aws_autoscaling_group.worker.name}", { "color": "#2ca02c", "label": "InService" } ],
                   [ ".", "GroupTerminatingInstances", ".", ".", { "color": "#d62728", "label": "Terminating" } ],
                   [ ".", "GroupPendingInstances", ".", ".", { "color": "#ff7f0e", "label": "Pending" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "label": "Count (max)",
                        "showUnits": false
                    }
                },
                "title": "${var.env_name} Worker - Autoscaling Group Instance State",
                "period": 60,
                "stat": "Average",
                "annotations": {
                    "horizontal": [
                        {
                            "label": "Minimum",
                            "value": ${var.asg_worker_min}
                        }
                    ]
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 46,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", "${aws_autoscaling_group.pivcac.name}", { "color": "#2ca02c", "label": "InService" } ],
                    [ ".", "GroupTerminatingInstances", ".", ".", { "color": "#d62728", "label": "Terminating" } ],
                    [ ".", "GroupPendingInstances", ".", ".", { "color": "#ff7f0e", "label": "Pending" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "label": "Count (max)",
                        "showUnits": false
                    }
                },
                "title": "${var.env_name} PIVCAC - Autoscaling Group Instance State",
                "period": 60,
                "stat": "Average",
                "annotations": {
                    "horizontal": [
                        {
                            "label": "Minimum",
                            "value": ${var.asg_pivcac_min}
                        }
                    ]
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 52,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", "${aws_autoscaling_group.outboundproxy.name}", { "color": "#2ca02c", "label": "InService" } ],
                    [ ".", "GroupTerminatingInstances", ".", ".", { "color": "#d62728", "label": "Terminating" } ],
                    [ ".", "GroupPendingInstances", ".", ".", { "color": "#ff7f0e", "label": "Pending" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "label": "Count (max)",
                        "showUnits": false
                    }
                },
                "title": "${var.env_name} Outboundproxy - Autoscaling Group Instance State",
                "period": 60,
                "stat": "Average",
                "annotations": {
                    "horizontal": [
                        {
                            "label": "Minimum",
                            "value": ${var.asg_outboundproxy_min}
                        }
                    ]
                }
            }
        }
    ]
}
EOF
}
