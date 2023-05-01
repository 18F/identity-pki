# Salesforcelib

A library that helps us authenticate and load data from Salesforce

## Usage

```
require 'lib/salesforcelib/lib/salesforcelib.rb'

client = Salesforcelib::Client.new
```

## Credentials

This is a command-line OAuth client. The client credentials are stored in shared SSM Parameters,
and this library will pull them down.  These parameters must be initialized in
the AWS account you are using.  For instance, to initialize in the `login-prod`
account, use the following commands after replacing the capitalized strings
passed to each `--value`:

~~~sh
aws-vault exec prod-admin -- aws ssm put-parameter --region us-west-2 --overwrite --type SecureString \
  --name /account/salesforce/instance_url --value 'SALESFORCE_INSTANCE_URL'

aws-vault exec prod-admin -- aws ssm put-parameter --region us-west-2 --overwrite --type SecureString \
  --name /account/salesforce/client_id --value 'SALESFORCE_CLIENT_ID'

aws-vault exec prod-admin -- aws ssm put-parameter --region us-west-2 --overwrite --type SecureString \
  --name /account/salesforce/client_secret --value 'SALESFORCE_CLIENT_SECRET'
~~~

To perform an OAauth token exchange, the library will start a local HTTP server,
pop open a browser and be ready to receive the token.

The tokens are stored in your keychain to simplify repeat usage.
