output "bucket_name" {
    description = "Name of the s3 secrets bucket that was created"
    value = "${aws_s3_bucket.secrets.id}"
}
