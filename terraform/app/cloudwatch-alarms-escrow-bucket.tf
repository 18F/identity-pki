/* Waiting on the issue mentioned next to period before this can be uncommented
resource "aws_cloudwatch_metric_alarm" "escrow_download_alarm" {
  alarm_name          = "${var.env_name}-escrow-s3-download-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  threshold           = "0"
  alarm_description   = "This alarm will trigger when the count of GetRequests is greater than 0 for a period of 1 minute for the ${aws_s3_bucket.escrow.id} S3 bucket"
  alarm_actions       = local.high_priority_alarm_actions
  treat_missing_data  = "notBreaching"
  metric_query {
    id = "m1"
    label = "GetRequests"
    return_data = "true"
    expression = "SELECT COUNT(GetRequests) FROM \"AWS/S3\" WHERE BucketName = '${aws_s3_bucket.escrow.id}'"
    #period = "60" # Waiting on https://github.com/hashicorp/terraform-provider-aws/issues/28617
  }
  ok_actions          = []
}
*/
