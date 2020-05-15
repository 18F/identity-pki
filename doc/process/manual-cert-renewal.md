# Manual ACME certificate renewal

Sometimes, certs expire when you least expect it. (Very inconsiderate of them!)

These are some steps that worked at least once to perform a manual renewal of
certificates.

## Terraform renewal for certs in an ALB, like idp.env.login.gov

Run terraform plan to see if it will be renewing the certs. Note that the
terraform ACME plan might renew but not deploy the certificates during the plan
phase due to the plugin working in weird ways.

You might have to change `min_days_remaining = 14` in order to get a renewal to
happen.

Terraform apply will update the ALB with the new certificate.

## Terraform + manual renewal for certs on a single host, like dashboard.env.login.gov

First do the terraform steps as above to get renewed certificates.

You probably don't want to rebuild the whole app host, since that's a huge
pain.

Instead, cd to `terraform/app` immediately after running `bin/tf-deploy` (so you
still have the correct .terraform remote set up).

List the available ACME certificate objects:

```
terraform state list | grep acme
```

You should see a number of entries that correspond to the certificates you want
to deploy to the app host, like `acme_certificate.dashboard`.

Get the contents of the certificate and key from terraform state:

```
terraform state show acme_certificate.dashboard
```

SSH to the app server and edit the certificate in `/etc/ssl/certs/`, for
example `/etc/ssl/certs/dashboard-cert.pem`. Be sure to include the leaf cert
and then the intermediate CA cert.

Edit the key in `/etc/ssl/private`, for example
`/etc/ssl/private/dashboard-key.pem`.

Repeat this process with all the cert/key pairs you are renewing.

Restart the servers to pick up the new certificate:

```
sudo service passenger restart
```

Check status

```
sudo passenger-status
```
