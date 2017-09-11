# Service Discovery

We currently use the AWS API to discover instances and AWS S3 to share
certificates.

We have a [service discovery
cookbook](https://github.com/18F/identity-devops/tree/master/kitchen/cookbooks/service_discovery/README.md),
which abstracts all the machinery to do this and provides a way to register and
discover instances as well as to upload and fetch certificates.  See the README
for that cookbook for more details.

Since this is in chef, any recipes that depend on discovered services must be
run periodically to stay up to date.
