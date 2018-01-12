# Login.gov SSH Access

## Jumphost SSH-Agent and Proxy Forwarding

There is an ssh jumphost set up now that we must use for all things. No direct
ssh access is allowed to anything but the jumphost, and all internal services
(ELK/Jenkins for now) must be accessed through the jumphost.

To use the jumpbox services, you will probably want to do two things:

* Forward your ssh-agent to the jumphost or use proxycommand when you ssh in so
  you can ssh to another machine through the jumphost.
* Forward a proxy port to the jumphost when you ssh in so you can use a web
  browser on internal services.

There are multiple ways to do this, so this page is a dump of all the available
options.  Eventually we should consolidate, but this works for now (and may not
matter when https://github.com/18F/identity-private/issues/1942 is done).

### Getting your PIV key set up

See:
https://github.com/18F/identity-private/wiki/Operations:-MacOSX-PIV-to-SSH-key-extraction

### Example "proxycommand" SSH Config

- Tab completion of anything in known hosts
- Transparent ssh to things like `chef.dev.login.gov` without any extra scripts
- Safer than using ssh agent forwarding.  See
  https://github.com/18F/identity-devops-private/issues/106 and
  https://heipei.github.io/2015/02/26/SSH-Agent-Forwarding-considered-harmful/.

Put this in `/.ssh/config` (replacing <username>):

```
Host jumphost.*.login.gov
User <username>
LocalForward 3128 localhost:3128
#PKCS11Provider /usr/local/lib/opensc-pkcs11.so
#SendEnv AWS_*

host *.*.login.gov !jumphost.*
user <username>
#PKCS11Provider /usr/local/lib/opensc-pkcs11.so
proxycommand bash -c 'set -x;  ssh "%r@jumphost.$(cut -f2 -d. <<< "%h").login.gov" -W "$(cut -f1 -d. <<< "%h"):%p"'
```

You can also add some lines to always use a PKCS11 provider for prod
specifically if you don't for other environments (if you use the `ubuntu` user:
https://github.com/18F/identity-devops-private/issues/137):

```
host *.prod.login.gov
PKCS11Provider /usr/local/lib/opensc-pkcs11.so
```

These are some globals that must go at the bottom of `~/.ssh/config` if you want
to set them.  You'll need to `mkdir ~/.ssh/sockets` if you enable connection
sharing:

```
# globals
host *
  # connection sharing (must mkdir ~/.ssh/sockets)
  ControlMaster auto
  ControlPath ~/.ssh/sockets/%r@%h-%p

  # leave connection open in the background for a while after your connection
  # exits (good for example if you log in/out of multiple machines beyond the
  # jumphost and want to avoid recreating the jumphost connection each time)
  ControlPersist 600

  # keepalive
  ServerAliveInterval 30
  ServerAliveCountMax 4

  HashKnownHosts no

# Long AWS hostnames can get a "too long for Unix domain socket" error with the
# default control path above, so use this one instead.
Host ec2-*.compute.amazonaws.com
  ControlPath ~/.ssh/sockets/%r@ec2-%C
```

When ssh reuses an existing controlmaster connection, it won't print the banner
/ MOTD. Whereas when it makes a new connection it will print the full banner and
MOTD.

If you are having some strange behavior when using connection sharing, where it
seems like ssh is ignoring your options (like `-A` for example), you may need to
use the `-M` option when you ssh.  This will tell ssh to create a new "master"
connection, which will use the options you pass in rather than reuse an old
connection that may have been created with different options.

### Helper Scripts for Common Workflows

These scripts rely on having your username set up as a default in `~/.ssh/config` for *all* jumphosts, like so:

```
# ~/.ssh/config
Host jumphost.prod.login.gov
       User zmargolis
       PKCS11Provider /usr/local/lib/pkcs11/opensc-pkcs11.so

Host jumphost.int.login.gov
       User zmargolis

# etc etc
```

#### `./bin/ssh.sh`

Opens an SSH session on a particular host

```
$ ./bin/ssh.sh idp1-0 int
# ...
user@idp:~$
```

#### `./bin/elk.sh`

Opens an SSH tunnel and forwards a port to proxy Kibana/ElasticSearch, it will
open a web browser to the port it proxies.

```
$ ./bin/elk.sh int
```

#### `./bin/jenkins.sh`

Ditto the `elk.sh` script but for Jenkins

```
$ ./bin/jenkins.sh int
```

#### `./bin/rails-console.sh`

Opens an Rails console

```
$ ./bin/ssh.sh idp1-0 int
# ...
irb(main):001:0>
```

### Manual SSH Jumping

You can do this with one command:

```
ssh -L3128:localhost:3128 -A <username>@jumphost.<env>.login.gov

```

Then, while that ssh session is active, any ssh keys that you are using in your
ssh-agent (check with 'ssh-add -l') should be available on the jumphost, and you
can set your browser up to route requests to \*.login.gov.internal to the proxy
port. I will leave that as an exercise for the reader, as every browser has it's
own way of doing that.

You can download Firefox and have it route all protocols over that proxied port.
So when you want to get inside the environment, you can just use Firefox.

To set up Firefox:

1. Open your browser and click **Preferences** on the top left corner.
2. Go to **Advanced**, then the **Network** tab, then click **settings...** next
   to **Connections**
3. Click **Manual Proxy Configuration** then fill *localhost* next to **HTTP
   Proxy** and *3128* next to **Port**
4. Check **Use this proxy server for all protocols**

Click OK and restart your browser.

## SSH to Github from servers

We have a machine github user, `identity-servers`
(https://github.com/identity-servers) that we use to allow our servers to clone
private github repos. There are also a number of repository-specific deploy
keys, but it gets to be a headache to manage a lot of them since they can only
be used on a single repo.

The SSH keys are delivered by chef to
`/etc/login.gov/keys/id_ecdsa.identity-servers` from the common directory in
the citadel S3 secrets bucket. All users who are in the `github` unix group are
able to access the keys.

Then we set SSH config in `/etc/ssh/ssh_config` to make SSH connections to
github.com use that key by default. Try it out by running `ssh git@github.com`
on a server.

The password and MFA key to fully log in to the identity-servers user are
stored in the prod AWS account in the `login-gov.shared-secrets` bucket.
