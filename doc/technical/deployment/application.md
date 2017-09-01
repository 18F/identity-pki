# Application Deployment

## Code Changes

To deploy new application code to an environment, push to `stages/<env_name>` in
`identity-idp` and then [Recycle The Instances](recycling-instances.md) to get
new instances with the updated code.

## Secrets Changes

To make secrets changes, you must [Change the Application Secrets in
S3](application-secrets.md) for your environment and then [Recycle The
Instances](recycling-instances.md) to get new instances with the updated
secrets.
