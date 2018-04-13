#!/bin/bash
# shellcheck disable=SC2086	# requires 0.4.4+

: ${PROJECT:=login-gov}
: ${AWS_REGION:=us-west-2}
: ${AWS_ACCOUNT:=894947205914}
: ${COPY:=aws s3 sync --sse aws:kms --region $AWS_REGION}
: ${DEST:=s3://${PROJECT}.secrets.${AWS_ACCOUNT}-${AWS_REGION}}


function usage() {
 cat >&2 << _EOF
Usage: $0 [ flags ] <environment> <hosttype>
    flags    ::= v(erbose) d(ebug)
    hosttype ::= jumphost | idp | worker ...

The generated host keys are uploaded to S3. The public halves
should be added to the local 'KnownHostsFile'. 

Environment:
    DEBUG   - prints commands with args as invoked
    VERBOSE - turns off 'quiet' behavior

Reference:
    https://github.com/18F/identity-private/wiki/Operations:-Adding-a-New-Environment
_EOF

exit $1
#ASG-fronted hosts will change their SSH host keys when instantiated.
#Connecting to ELB-fronted hosts is also non-deterministic.
#
#If the SSH client configuration retains KnownHosts, noisy error
#messages are displayed upon divergence. This is particularly
#important when connecitng to jumphosts (SSH relay) to prevent Man-
#in-the-Middle attacks. The jumphost Chef recipe re-populates the
#keys during it's run so that all such hosts 'look' the same 
#regardless of their Instance number or what Availability-Zone they
#might belong to.
}

function run() { echo >&2 "+ $*"; "$@"; }

# non-empty substitution can wreak havoc
[ -n "${VERBOSE+x}" ] && VERBOSE=
[ -n "${DEBUG+x}" ] && DEBUG=

while [ $# -gt 0 ]; do
  case $1 in
    -h) usage
	;;
    -v) VERBOSE=
	shift
	;;
    -d) DEBUG=
	shift
	;;
    *)	break
  esac
done

[ $# -lt 2 ] && usage 2


#--- main ---

ENV="$1"
INSTANCE="$2"

_tmpdir="$(mktemp -d)"
# shellcheck disable=SC2154
trap '{ rc=$?; rm -fr $_tmpdir; exit $rc; }' EXIT HUP INT QUIT TERM

set -e

( cd "$_tmpdir"
  for t in ecdsa rsa ed25519; do
    run ssh-keygen ${VERBOSE- -q} -t $t -C "$ENV-$INSTANCE" -N '' -f ssh_host_${t}_key
  done

# shellcheck disable=SC2086
  run $COPY . "$DEST/$ENV/$INSTANCE/"
)

