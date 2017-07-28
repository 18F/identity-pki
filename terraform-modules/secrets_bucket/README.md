# Secrets Bucket

Use this module to create an s3 bucket for storing secrets.  Given a prefix,
will properly namespace the bucket by region and account id and return the full
name to the caller.

Supports enforcing kms encryption by a specific kms key.
