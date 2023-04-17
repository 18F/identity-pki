# Salesforcelib

A library that helps us authenticate and load data from Salesforce

## Usage

```
require 'lib/salesforcelib/lib/salesforcelib.rb'

client = Salesforcelib::Client.new
```

## Credentials

This is a command-line OAuth client. The client credentials are stored in shared S3 buckets,
and this library will pull them down.

To perform an OAauth token exchange, the library will start a local HTTP server,
pop open a browser and be ready to receive the token.

The credentials are stored in your keychain to simplify repeat usage.

### Uploading Salesforce Credentials to S3

Write the values as plaintext files to keys in the top level of the secrets bucket. The code will `chomp` trailing newlines, so don't sweat removing those.

```bash
bucket="login-gov.secrets.$ACCOUNT_ID-us-west-2"
echo "CLIENT_ID" | aws-vault sandbox-power exec -- aws s3 cp - s3://$bucket/salesforce_client_id
echo "CLIENT_SECRET" | aws-vault sandbox-power exec -- aws s3 cp - s3://$bucket/salesforce_client_secret
echo "INSTANCE_URL" | aws-vault sandbox-power exec -- aws s3 cp - s3://$bucket/salesforce_client_instance_url
```
