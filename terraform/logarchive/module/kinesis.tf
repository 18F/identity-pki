resource "aws_kinesis_stream" "logarchive" {
  name             = "${local.aws_alias}-${data.aws_region.current.name}"
  retention_period = 24

  shard_level_metrics = [
    "IncomingBytes",
    "IncomingRecords",
    "IteratorAgeMilliseconds",
    "OutgoingBytes",
    "OutgoingRecords",
    "ReadProvisionedThroughputExceeded",
    "WriteProvisionedThroughputExceeded",
  ]

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }
}

resource "aws_kinesis_stream_consumer" "logarchive" {
  name       = "logarchive_kinesis"
  stream_arn = aws_kinesis_stream.logarchive.arn
}
