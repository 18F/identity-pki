# ----------------------------------------------------------------------------------------------------------------------
# Creates Kinesis Strea for pinpont to stream events
# ----------------------------------------------------------------------------------------------------------------------


resource "aws_kinesis_stream" "pinpoint_kinesis_stream" {
  name             = "${var.env}-pinpoint-kinesis-stream"
  shard_count      = 1
  retention_period = 24
  shard_level_metrics = [
    "IncomingBytes",
    "IncomingRecords",
    "IteratorAgeMilliseconds",
    "OutgoingBytes",
    "OutgoingRecords",
    "ReadProvisionedThroughputExceeded",
    "WriteProvisionedThroughputExceeded"
  ]
}
