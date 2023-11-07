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
                    [ "AWS/RDS", ".", "DBInstanceIdentifier", "${module.idp_aurora_uw2.writer_instance}", { "label": "AuroraDB (Writer Instance)" } ],
                    %{for id in module.idp_aurora_uw2.reader_instances~}
                    [ "...", "${id}", { "label": "AuroraDB (Replica ${index(module.idp_aurora_uw2.reader_instances, id) + 1})" } ],
                    %{endfor~}
                    [ "AWS/ElastiCache", ".", "CacheClusterId", "${var.env_name}-idp-001", { "label": "Primary Cache (1)" } ],
                    [ "...", "${var.env_name}-idp-002", { "label": "Primary Cache (2)" } ]
                    %{if var.enable_redis_ratelimit_instance~}
                    , [ "...", "${var.env_name}-ratelimit-001", { "label": "Rate Limit Cache (1)" } ],
                    [ "...", "${var.env_name}-ratelimit-002", { "label": "Rate Limit Cache (2)" } ]
                    %{endif~}

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
                    [ "AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "${module.idp_aurora_uw2.writer_instance}", { "label": "AuroraDB (Writer Instance)" } ],
                    %{for id in module.idp_aurora_uw2.reader_instances~}
                    [ "...", "${id}", { "label": "AuroraDB (Replica ${index(module.idp_aurora_uw2.reader_instances, id) + 1})" } ],
                    %{endfor~}

                    [ "AWS/ElastiCache", "CurrConnections", "CacheClusterId", "${var.env_name}-idp-001", { "label": "Primary Cache (1)" } ],
                    [ "...", "${var.env_name}-idp-002", { "label": "Primary Cache (2)" } ]
                    %{if var.enable_redis_ratelimit_instance~}
                    , [ "...", "${var.env_name}-ratelimit-001", { "label": "Rate Limit Cache (1)" } ],
                    [ "...", "${var.env_name}-ratelimit-002", { "label": "Rate Limit Cache (2)" } ]
                    %{endif~}
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
                    [ "AWS/RDS", "WriteIOPS", "DBInstanceIdentifier", "${module.idp_aurora_uw2.writer_instance}", { "label": "Write" } ],
                    [ ".", ".", "DBClusterIdentifier", "${module.idp_aurora_uw2.cluster_id}", { "label": "Write (Cluster)" } ],
                    [ ".", "ReadIOPS", "DBInstanceIdentifier", "${module.idp_aurora_uw2.writer_instance}", { "label": "Read" } ],
                    %{for id in module.idp_aurora_uw2.reader_instances~}
                    [ "...", "${id}", { "label": "Read (Replica ${index(module.idp_aurora_uw2.reader_instances, id) + 1})" } ],
                    %{endfor~}
                    [ ".", ".", "DBClusterIdentifier", "${module.idp_aurora_uw2.cluster_id}", { "label": "Read (Cluster)" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "title": "${var.env_name} IdP - AuroraDB Instance IOPS",
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
                    [ "${var.env_name}/idp-ialx", "idv-enter-password-submitted", { "label": "idv-enter-password-submitted [sum:$${SUM}, max:$${MAX}]" } ]
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
            "y": 8,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "${var.env_name}/idp-worker", "queue-time-milliseconds", { "color": "#2ca02c", "label": "queue time p99", "stat": "p99" } ],
                    [ "${var.env_name}/idp-worker", "queue-time-milliseconds", { "color": "#1f77b4", "label": "queue time p90", "stat": "p90" } ],
                    [ "${var.env_name}/idp-worker", "queue-time-milliseconds", { "color": "#d62728", "label": "queue time p50", "stat": "p50" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "${var.env_name} Worker - Background Job queue time",
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "showUnits": false,
                        "label": "Queue Time (ms)"
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 8,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                  [ "AWS/ElastiCache", "EngineCPUUtilization", "CacheClusterId", "${aws_elasticache_replication_group.idp.id}-001", "CacheNodeId", "0001", { "color": "#2ca02c", "label": "${aws_elasticache_replication_group.idp.id}-001" } ],
                  [ "AWS/ElastiCache", "EngineCPUUtilization", "CacheClusterId", "${aws_elasticache_replication_group.idp.id}-002", "CacheNodeId", "0001", { "color": "#ff7f0e", "label": "${aws_elasticache_replication_group.idp.id}-002" } ]
                  %{if var.enable_redis_ratelimit_instance~}
                    , [ "...", "${aws_elasticache_replication_group.ratelimit[0].id}-001", "CacheNodeId", "0001", { "label": "${aws_elasticache_replication_group.ratelimit[0].id}-001" } ],
                    [ "...", "${aws_elasticache_replication_group.ratelimit[0].id}-002", "CacheNodeId", "0001", { "label": "${aws_elasticache_replication_group.ratelimit[0].id}-002" } ]
                  %{endif~}
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "${var.env_name} Redis - Engine CPU Utilization (Average)",
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "showUnits": false,
                        "label": "CPU Utilization (%)"
                    }
                },
                "stat": "Average"
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
                    %{if var.worker_cluster_instances >= 2~}
                    [ "AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "${module.worker_aurora_uw2.writer_instance}", { "label": "AuroraDB (Writer Instance)" } ],
                    %{for id in module.worker_aurora_uw2.reader_instances~}
                    [ "...", "${id}", { "label": "AuroraDB (Replica ${index(module.worker_aurora_uw2.reader_instances, id) + 1})" } ]
                    %{endfor~}
                    %{endif~}
                    %{if var.worker_cluster_instances == 1~}
                    [ "AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "${module.worker_aurora_uw2.writer_instance}", { "label": "AuroraDB (Writer Instance)" } ]
                    %{endif~}
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "${var.env_name} Worker - Database Connections",
                "stat": "Maximum",
                "period": 60,
                "yAxis": {
                    "left": {
                        "label": "Connections",
                        "showUnits": false
                    }
                }
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
                    %{if var.worker_cluster_instances >= 2~}
                    [ "AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${module.worker_aurora_uw2.writer_instance}", { "label": "AuroraDB (Writer Instance)" } ],
                    %{for id in module.worker_aurora_uw2.reader_instances~}
                    [ "...", "${id}", { "label": "AuroraDB (Replica ${index(module.worker_aurora_uw2.reader_instances, id) + 1})" } ]
                    %{endfor~}
                    %{endif~}
                    %{if var.worker_cluster_instances == 1~}
                    [ "AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${module.worker_aurora_uw2.writer_instance}", { "label": "AuroraDB (Writer Instance)" } ]
                    %{endif~}
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "${var.env_name} Worker - CPU Utilization (Average)",
                "stat": "Average",
                "period": 60,
                "yAxis": {
                    "left": {
                        "label": "CPU Utilization (%)",
                        "showUnits": false
                    }
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
                    [ "AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", "${module.outboundproxy_uw2.proxy_asg_name}", { "color": "#2ca02c", "label": "InService" } ],
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
        },
        {
            "type": "metric",
            "x": 0,
            "y": 20,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    %{if var.idp_cluster_instances >= 2~}
                    %{for id in module.idp_aurora_uw2.reader_instances~}
                    [ "AWS/RDS", "DiskQueueDepth", "DBInstanceIdentifier", "${id}", { "label": "AuroraDB (Replica ${index(module.idp_aurora_uw2.reader_instances, id) + 1})" } ],
                    %{endfor~}
                    [ "AWS/RDS", "DiskQueueDepth", "DBInstanceIdentifier", "${module.idp_aurora_uw2.writer_instance}", { "label": "AuroraDB (Writer Instance)" } ]
                    %{endif~}
                    %{if var.idp_cluster_instances == 1~}
                    [ "AWS/RDS", "DiskQueueDepth", "DBInstanceIdentifier", "${module.idp_aurora_uw2.writer_instance}", { "label": "AuroraDB (Writer Instance)" } ]
                    %{endif~}
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "${var.env_name} IdP - DiskQueueDepth",
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "label": "Queue Depth (Count)",
                        "showUnits": false
                    }
                },
                "stat": "Average"
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
                    %{if var.idp_cluster_instances >= 2~}
                    %{for id in module.idp_aurora_uw2.reader_instances~}
                    [ "AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", "${id}", { "label": "AuroraDB (Replica ${index(module.idp_aurora_uw2.reader_instances, id) + 1})" } ],
                    %{endfor~}
                    [ "AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", "${module.idp_aurora_uw2.writer_instance}", { "label": "AuroraDB (Writer Instance)" } ]
                    %{endif~}
                    %{if var.idp_cluster_instances == 1~}
                    [ "AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", "${module.idp_aurora_uw2.writer_instance}", { "label": "AuroraDB (Writer Instance)" } ]
                    %{endif~}
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "${var.env_name} IdP - FreeableMemory",
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "label": "Freeable Memory (Bytes)",
                        "showUnits": false
                    }
                },
                "stat": "Average"
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
                        %{if var.idp_cluster_instances >= 2~}
                        %{for id in module.idp_aurora_uw2.reader_instances~}
                        [ "AWS/RDS", "ReadLatency", "DBInstanceIdentifier", "${id}", { "label": "AuroraDB (Replica ${index(module.idp_aurora_uw2.reader_instances, id) + 1})" } ],
                        %{endfor~}
                        [ "AWS/RDS", "ReadLatency", "DBInstanceIdentifier", "${module.idp_aurora_uw2.writer_instance}", { "label": "AuroraDB (Writer Instance)" } ]
                        %{endif~}
                        %{if var.idp_cluster_instances == 1~}
                        [ "AWS/RDS", "ReadLatency", "DBInstanceIdentifier", "${module.idp_aurora_uw2.writer_instance}", { "label": "AuroraDB (Writer Instance)" } ]
                        %{endif~}
                    ],
                    "view": "timeSeries",
                    "stacked": false,
                    "region": "${var.region}",
                    "title": "${var.env_name} IdP - ReadLatency",
                    "period": 60,
                    "yAxis": {
                        "left": {
                            "min": 0,
                            "label": "Read Latency (Milliseconds)",
                            "showUnits": false
                        }
                    },
                    "stat": "Average"
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
                    %{if var.idp_cluster_instances >= 2~}
                    %{for id in module.idp_aurora_uw2.reader_instances~}
                    [ "AWS/RDS", "NetworkTransmitThroughput", "DBInstanceIdentifier", "${id}", { "label": "AuroraDB (Replica ${index(module.idp_aurora_uw2.reader_instances, id) + 1})" } ],
                    %{endfor~}
                    [ "AWS/RDS", "NetworkTransmitThroughput", "DBInstanceIdentifier", "${module.idp_aurora_uw2.writer_instance}", { "label": "AuroraDB (Writer Instance)" } ]
                    %{endif~}
                    %{if var.idp_cluster_instances == 1~}
                    [ "AWS/RDS", "NetworkTransmitThroughput", "DBInstanceIdentifier", "${module.idp_aurora_uw2.writer_instance}", { "label": "AuroraDB (Writer Instance)" } ]
                    %{endif~}
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "${var.env_name} IdP - NetworkTransmitThroughput",
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "label": "Network Transmit Throughput (MB/Second)",
                        "showUnits": false
                    }
                },
                "stat": "Average"
            }
        }
    ]
}
EOF
}
