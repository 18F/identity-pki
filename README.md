Identity-PKI
============

PIV/CAC support for login.gov.

### Local development

#### Dependencies

- Ruby 3.0
- [Postgresql](http://www.postgresql.org/download/)

#### Setting up and running the app

1. Make sure you have a working development environment with all the
  [dependencies](#dependencies) installed. On OS X, the easiest way
  to set up a development environment is by running our [Laptop]
  script. The script will install all of this project's dependencies.

  If using rbenv, you may need to alias your specific installed ruby
  version to the more generic version found in the `.ruby-version` file.
  To do this, use [`rbenv-aliases`](https://github.com/tpope/rbenv-aliases):

  ```
  git clone git://github.com/tpope/rbenv-aliases.git "$(rbenv root)/plugins/rbenv-aliases" # install rbenv-aliases per its documentation

  rbenv alias 3.0 3.0.6 # create the version alias
  ```

2. Make sure Postgres is running.

  For example, if you've installed the laptop script on OS X, you can start the services like this:

  ```
  $ brew services start postgresql
  ```

3. Create the development and test databases:

  ```
  $ psql -c "CREATE DATABASE identity_pki_dev;"
  $ psql -c "CREATE DATABASE identity_pki_test;"
  ```

4. Run the following command to set up the environment

  - The first time, it will prompt for a passphrase for the root certificate. You can put anything as long as you remember it, it's just for development. To keep it simple, try `salty pickles`.

  - Make sure to [trust the root SSL certificate](#trust-the-root-ssl-certificate)

  ```
  $ make setup
  ```

  This command copies sample configuration files, installs required gems
  and sets up the database.

5. Run the app server with:

  ```
  $ make run
  ```

Before making any commits, you'll also need to run `overcommit --sign.`
This verifies that the commit hooks defined in our `.overcommit.yml` file are
the ones we expect. Each change to the `.overcommit.yml` file, including the initial install
performed in the setup script, will necessitate a new signature.

For more information, see [overcommit](https://github.com/brigade/overcommit)

If you want to measure the app's performance in development, set the
`rack_mini_profiler` option to `'on'` in `config/application.yml` and
restart the server. See the [rack_mini_profiler] gem for more details.

[Laptop]: https://github.com/18F/laptop
[rack_mini_profiler]: https://github.com/MiniProfiler/rack-mini-profiler

### Running the app locally with the IDP

#### Trust the root SSL certificate

Most of the root certificate management is handled by `bin/setup` but there are some manual steps

1. Open the Keychain Access app

2. Go to "Certificates" bottom left section

3. Find the cert named "**identity-pki Development Certificate**" open its settings

4. Under the "Trust" section, select "Always Trust" for the top-level "When using this certificate" dropdown

#### Cleaning up the root SSL certificate

1. Delete the certificate files:

  ```
  pushd config/local-certs/
  make clean
  popd
  ```

2. Open Keychain Access and delete the certificate named "**identity-pki Development Certificate**"

#### Using Docker Locally

1. Download, install, and launch [Docker](https://www.docker.com/products/docker-desktop).

1. Build the Docker containers: `docker-compose build`

1. Run `make docker_setup` to copy configuration files and bootstrap the database.

1. Start the Docker containers `docker-compose up` and `open https://localhost:8443` (If you see an SSL error, check [Trust the root SSL certificate](#trust-the-root-ssl-certificate) instructions)


### Certificate Authority Management

The PIV/CAC service relies on having all of the certificate authorities (issuing
certificates). If a certificate authority is missing, then any client certificates
signed by that authority will not be recognized as valid.

All certificates have to link back to a trusted root. Trusted roots are implicitly
trusted as long as they aren't expired. Any certificate authority that can't be
traced back to a trusted root will be ignored.

Certificate authorities are made trusted roots by listing their key id in the
`config/application.yml`. The `trusted_ca_root_identifiers` configuration attribute
is a comma-delimited list of key ids.

#### Managing OCSP

OCSP is a real-time revocation status protocol for certificates. We contact the OCSP
server when we check the validity of a certificate rather than relying on a periodic
refresh of CRLs. CRLs become a fall-back if we aren't able to contact the OCSP server.

If we have a OCSP URL on record for an issuing certificate, we use that. Otherwise, we
find the OCSP URL in the certificate we're verifying. If we are not able to get a
response from the OCSP server, we fall back to the CRL information we've cached.

If we get a "revoked" status from the OCSP server, we record that for future checks so
we don't have to go back to the OCSP server.

Once a certificate is marked as revoked, we don't "unrevoke." We will always refuse to
accept the certificate as valid unless the revocation status is removed from the
database.

#### Managing Certificate Revocation Lists (CRLs)

The application does not download CRLs. Instead, it expects revoked serial numbers to
be listed in the `certificate_revocations` table.

##### Loading CRL Metadata

Use the `rake crls:load` command to load a CSV of CRL metadata into the database. This
command takes an optional filename argument if you aren't providing the CSV on STDIN.

The CSV has the following columns:
1. certificate authority key id
2. valid not before date/time
3. valid not after date/time
4. certificate authority subject
5. CRL HTTP URL

##### Dumping CRL Metadata

Use the `rake crls:dump` command to dump a CSV of CRL metadata from the database. This
command takes an optional filename argument if you aren't wanting the CSV on STDOUT.

The CSV has the same columns as for `crls:load`.

##### Updating CRLs

Use the `rake crls:update` command to fetch the CRLs of configured certificate authorities
and add any serial numbers to the database.

N.B.: Because of the CRL security model, the command will not fetch or update CRLs for
certificate authorities that aren't linked to a trusted root. Make sure your trusted roots
are configured if you aren't seeing CRLs fetched as you expect.
