# Dependencies

## Mac OSX

### AWS CLI

Install [Homebrew](https://brew.sh) (Ignore this step if you have already run the  [laptop script](https://github.com/18F/laptop)).

```shell
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

Install  [AWS CLI](https://aws.amazon.com/cli/)  in order to manage services from the command line.

``` shell
brew install awscli
```
or
``` shell
brew upgrade awscli
```

[Configure the AWS
CLI](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)
with the AWS region (currently us-west-2) and credentials you want to use.  The
18f-identity specific signin link is here:
https://18f-identity.signin.aws.amazon.com/console.  Test your configuration by
running `aws s3 ls`.

### Terraform

Install [Terraform CLI](https://www.terraform.io/docs/commands/) and
[Terraform ACME Provider Plugin](https://github.com/paybyphone/terraform-provider-acme).

Most of our environments use terraform 0.8.8.
    - We are in the process of upgrading from 0.8.8, check back
      [here](https://github.com/18F/identity-private/issues/1877) for the status of that upgrade.

You can use `bin/brew-switch-terraform.sh` to manage installed versions of
Terraform and the Terraform ACME plugin. (This script relies on Homebrew and
only works on macOS.) There will be multiple versions of Terraform installed,
but only one will be symlinked onto your PATH at any given time. Run
`terraform --version` to see which one.

We use a Terraform plugin that adds an ACME provider used to generate our Let's
Encrypt TLS certificates. This will be installed automatically when you run
`bin/brew-switch-terraform.sh`.

Run the script to install and switch to Terraform 0.9.6. Follow the prompts
when it asks to create a `~/.terraformrc` to manage your ACME plugin:

```shell
bin/brew-switch-terraform.sh 0.9.6
```

Run the script to install and switch to Terraform 0.8.8:

```
bin/brew-switch-terraform.sh 0.8.8
```

The `deploy` script will enforce for each environment which versions of
Terraform have been tested on that environment. (See environment variables
discussion below.)

### Chef

This is not needed unless you want to do chef server administration from your
machine.  Most instances should have cloud-init configuration to bootstrap
themselves.  See the [Getting Started Guide](../getting-started.md) for details.

Install [ChefDK](https://downloads.chef.io/chefdk).

```shell
brew install Caskroom/cask/chefdk
```
