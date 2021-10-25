# sandbox_ses - Inbound email delivery to a S3 bucket

This terraform module contains inbound SES email configuration used for
non-prod email reception.   It is not suitable for handling sensitive
information.

If using kms:sse encryption for the destination S3 bucket remember
to give AWS SES access to the KMS key used.  See
 https://docs.aws.amazon.com/kms/latest/developerguide/services-ses.html#services-ses-permissions
 