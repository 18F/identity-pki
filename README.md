Identity-PKI
============

PIV/CAC support for login.gov.

### Local development

#### Dependencies

- Ruby 2.3
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

  rbenv alias 2.3 2.3.5 # create the version alias
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

4. Run the following command to set up the environment:

  ```
  $ make setup
  ```

  This command copies sample configuration files, installs required gems
  and sets up the database.

5. Run the app server with:

  ```
  $ make run
  ```

**TODO** Instructions for setting up NGinx to handle TLS/SSL.

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

### Viewing the app locally

Once it is up and running, the app will be accessible at
`http://localhost:3001/` by default.
