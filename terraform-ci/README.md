# Terraform for CI dependencies

This directory contains terraform configuration for any AWS pre setup that is
needed to run our test kitchen ec2 integration tests.

Current functionality:

- Creates an IAM role that allows access to the s3 `integration` environment
  secrets bucket (this bucket is created/populated manually).  This role can be
  used by the integration tests.

Future functionality:

- Spin up a VPC that the integration tests can run in (rather than reusing the
  `dev` environment jumphost subnet which is what they do now).
- Create an IAM role that restricts access to only that VPC.
