# Chef Secrets

## Changing Secrets

All our secrets are stored in S3, and encrypted using KMS. The secrets are
downloaded when Chef is run using Citadel, using the `config_loader` cookbook in `identity-cookbooks`.

The bucket that is used is configured as the `citadel.bucket` Chef attribute,
whose value is:
```
default['citadel']['bucket'] = "#{node['config_loader']['bucket_prefix']}.#{Chef::Recipe::AwsMetadata.get_aws_account_id}-#{Chef::Recipe::AwsMetadata.get_aws_region}"
```
* The `config_loader.bucket_prefix` default is `login-gov.secrets`, as is set in
the `default_attributes` of the `base` role.
* The `aws_metadata` cookbook has a class which uses the methods `get_aws_account_id` and `get_aws_region` to fill the appropriate values.

You can use the AWS CLI to work with these secrets, but you may need to pass
`--sse aws:kms` since we do server side encryption.  Here are some examples:

```
# view a secret in S3
aws s3 cp --sse aws:kms s3://login-gov.secrets.894947205914-us-west-2/int/equifax_wsdl - ; echo
# copy a secret from int to dev
aws s3 cp --sse aws:kms s3://login-gov.secrets.894947205914-us-west-2/{int,dev}/equifax_wsdl
# list secrets in the int env
aws s3 ls s3://login-gov.secrets.894947205914-us-west-2/int/
```

## Deploying Secrets Changes

To get the application to pick up the secrets changes, you must [Recycle The
Instances](recycling-instances.md).
