module "kms_logging" {
  source = "github.com/18F/identity-terraform//kms_log?ref=a58d0581b04b3562885dca32e07c0751e794db88"

  #source = "../../identity-terraform/kms_log"

  env_name                   = var.env_name
  kmslogging_service_enabled = var.kmslogging_enabled
  sns_topic_dead_letter_arn  = var.slack_events_sns_hook_arn
  kinesis_shard_count        = var.kms_log_kinesis_shards
  ec2_kms_arns               = concat([aws_iam_role.idp.arn],var.db_restore_role_arns)
}

# alert if we are disabling or deleting a key, which would be terrible for us!
resource "aws_cloudwatch_metric_alarm" "kms_keydeletion" {
  count = var.kmskeydeletealert_enabled
  alarm_name = "${var.env_name}_kms_keydeletion"
  alarm_description = "A CloudWatch Alarm that triggers if customer created CMKs get disabled or scheduled for deletion."
  metric_name = "${var.env_name}-KMSCustomerKeyDeletion"
  namespace = "${var.env_name}/kmslog"
  statistic = "Sum"
  period = "60"
  threshold = "1"
  evaluation_periods = "1"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_actions = [ "${var.slack_events_sns_hook_arn}" ]
  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_log_metric_filter" "kmskeydisabledordeleted" {
  count = var.kmskeydeletealert_enabled
  log_group_name = "/aws/lambda/${var.env_name}-cloudtrail-kms"
  pattern = "{ ($.eventSource = kms.amazonaws.com) &&  (($.eventName=DisableKey) || ($.eventName=ScheduleKeyDeletion)) }"
  name = "${var.env_name}-KMSCustomerKeyDeletion"

  metric_transformation {
    name = "${var.env_name}-KMSCustomerKeyDeletion"
    value = "1"
    namespace = "${var.env_name}/kmslog"
  }
}
