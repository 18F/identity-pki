output "bucket_name" {
    description = "Name of the s3 logs bucket that was created"
    value = "${aws_s3_bucket.logs.id}"
}
