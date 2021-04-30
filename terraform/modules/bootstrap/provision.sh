#!/bin/bash
# shellcheck disable=SC2230

# Send all output to syslog and serial console unless we're being run by
# systemd, in which case assume that systemd is handling output logging.
# shellcheck disable=SC2009
if ! ps -o cgroup= $$ | grep ".service" >/dev/null ; then
    exec > >(tee >(logger -t provision.sh -s 2>/dev/console)) 2>&1
fi

set -euo pipefail

INFO_DIR=/etc/login.gov/info
embedded_bin='/opt/chef/embedded/bin'

usage() {
    cat >&2 <<EOM
usage: $(basename "$0") [options] S3_SSH_KEY_URL GIT_CLONE_URL

This script helps provision an instance using chef. Steps it runs:

- Install key dependencies
- Download an SSH key from S3
- Clone the specified git repo
- Inside the git repo there must be a chef repo:
  - Run berkshelf to download and vendor any needed cookbooks
  - Run chef-client in local mode

S3_SSH_KEY_URL:    Should be an S3 URL where the SSH key used for bootstrapping
                   can be found. This should be an SSH key that has read
                   privileges on the identity-devops-private repo.

GIT_CLONE_URL:     The URL to use for cloning identity-devops-private. This URL
                   should be an SSH git URL.

options:
    --git-ref REF               Check out REF in id-do-private after cloning.
    --kitchen-subdir DIR        The subdirectory to cd to for running chef.
    --asg-name ASG_NAME         Name of the current autoscaling group, used in
                                conjunction with --lifecycle-hook-name.
    --lifecycle-hook-name NAME  The name of the lifecycle hook to notify when
                                provisioning succeeds or fails. We'll complete
                                the lifecycle hook with a CONTINUE result on
                                success, or an ABANDON result on failure.

                                If \$INFO_DIR/skip_abandon_hook exists, don't
                                send any result on failure, which will keep the
                                instance alive until the abandon timeout.

Needed config files:

    Inside the git repo, this script expects to find a chef repository in a
    subdirectory defined by --kitchen-subdir, or 'chef' by default.

    This directory must contain a 'chef-client.rb' file that contains
    everything needed to successfully run chef in local mode, including
    - environment
    - run list (typically via json_attribs file)
    - cookbook_path
    - chef_repo_path (will be the parent directory of the script)

Proxy configuration:

    These files in $INFO_DIR/ will be used to set proxy environment
    variables (\$http_proxy, \$https_proxy, \$no_proxy, ...)

    $INFO_DIR/proxy_server    Name of the outbound proxy server
    $INFO_DIR/proxy_port      TCP port of the outbound proxy server
    $INFO_DIR/no_proxy_hosts  The no_proxy string containing a comma-separated
                              list of names that should not use the proxy.

Debugging after failure with lifecycle hooks:

    If the file $INFO_DIR/skip_abandon_hook exists, then the ABANDON signal
    will not be sent even on provision failure. Create this file to keep an
    instance alive for debugging. The instance will remain in the pending state
    and won't be terminated until it reaches the lifecycle hook's abandon
    timeout.

EOM
}

run() {
    echo >&2 "+ $*"
    "$@"
}

assert_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo >&2 "error: this script must be run as root"
        return 2
    fi
}

configure_proxy() {
    http_proxy="http://$proxy_server:$proxy_port"
    https_proxy="$http_proxy"
    run tee /etc/profile.d/proxy-config.sh >&2 <<EOF
export http_proxy='$http_proxy'
export https_proxy='$https_proxy'
export no_proxy='$no_proxy_hosts'
export NEW_RELIC_PROXY_HOST='$proxy_server'
export NEW_RELIC_PROXY_PORT='$proxy_port'
EOF
    # shellcheck disable=SC1091
    source /etc/profile.d/proxy-config.sh

    # Also add vars to /etc/environment so that anything reading this early on
    # before the main chef run will still get the appropriate proxy.
    if ! grep "^http_proxy=" /etc/environment >/dev/null; then
        run tee -a /etc/environment >&2 <<EOF
# Proxy vars added by provision.sh
http_proxy='$http_proxy'
https_proxy='$https_proxy'
no_proxy='$no_proxy_hosts'
NEW_RELIC_PROXY_HOST='$proxy_server'
NEW_RELIC_PROXY_PORT='$proxy_port'
EOF
    fi
}

set_newrelic_enpoints() {
if ! grep "^NEW_RELIC_HOST=" /etc/environment >/dev/null; then
        run tee -a /etc/environment >&2 <<EOF
NEW_RELIC_HOST=gov-collector.newrelic.com
EOF
    fi
}

maybe_complete_lifecycle_hook() {
    local result="$1"

    if [ -n "$asg_name" ] && [ -n "$asg_lifecycle_hook_name" ]; then
        echo >&2 "Completing ASG lifecycle hook with result: $result"
        complete_lifecycle_hook "$asg_name" "$asg_lifecycle_hook_name" \
            "$result" "$sns_topic_arn"
    else
        echo >&2 "No lifecycle hook was specified, nothing to notify."
    fi
}

maybe_lifecycle_hook_heartbeat() {
    if [ -n "$asg_name" ] && [ -n "$asg_lifecycle_hook_name" ]; then
        echo >&2 "Sending heartbeat to ASG lifecycle hook"
        lifecycle_hook_heartbeat "$asg_name" "$asg_lifecycle_hook_name"
    else
        echo >&2 "No lifecycle hook was specified, nothing to notify."
    fi
}

# usage: complete_lifecycle_hook ASG_NAME ASG_LIFECYCLE_HOOK_NAME RESULT SNS_TOPIC
#
# Notify the specified lifecycle hook with RESULT.
#
complete_lifecycle_hook() {
    local asg_name asg_lifecycle_hook_name result
    asg_name="$1"
    asg_lifecycle_hook_name="$2"
    result="$3"
    sns_topic_arn="$4"

    local instance_id az v2_token
    #instance_id="$(ec2metadata --instance-id)"
    #az="$(ec2metadata --availability-zone)"
    v2_token=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60"`
    instance_id=`curl -sSf http://169.254.169.254/latest/meta-data/instance-id -H "X-aws-ec2-metadata-token: $v2_token"`
    region="$(curl -sSf http://169.254.169.254/latest/meta-data/placement/region -H "X-aws-ec2-metadata-token: $v2_token")"

    # send a notice that the instance was abandoned
    if [ -n "${sns_topic_arn}" -a "${result}" == "ABANDON" ]; then
        message="Instance ${instance_id} for ASG ${asg_name} was ABANDONED.  Fatal error in provisioning."
        run aws sns publish \
            --region "${region}" \
            --topic-arn "${sns_topic_arn}" \
            --message "${message}" \
            --subject "${asg_name} instance ABANDONED"
    fi

    run aws autoscaling complete-lifecycle-action \
        --region "${region}" \
        --auto-scaling-group-name "${asg_name}" \
        --lifecycle-hook-name "${asg_lifecycle_hook_name}" \
        --instance-id "${instance_id}" \
        --lifecycle-action-result "${result}"
}

# usage: lifecycle_hook_heartbeat ASG_NAME ASG_LIFECYCLE_HOOK_NAME
#
# Send a keep alive heartbeat to the specified lifecycle hook.
#
lifecycle_hook_heartbeat() {
    local asg_name asg_lifecycle_hook_name
    asg_name="$1"
    asg_lifecycle_hook_name="$2"

    local instance_id az v2_token
    v2_token=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60"`
    instance_id=`curl -sSf http://169.254.169.254/latest/meta-data/instance-id -H "X-aws-ec2-metadata-token: $v2_token"`
    region="$(curl -sSf http://169.254.169.254/latest/meta-data/placement/region -H "X-aws-ec2-metadata-token: $v2_token")"

    run aws autoscaling record-lifecycle-action-heartbeat \
        --region "${region}" \
        --auto-scaling-group-name "$asg_name" \
        --lifecycle-hook-name "$asg_lifecycle_hook_name" \
        --instance-id "$instance_id"
}


# --

# If we appear to be a cloud-init user-data script running as root, exit zero.
if [[ $0 == /var/lib/cloud/instance/scripts/* ]] && \
    [ $# -eq 0 ] && [ "$(id -u)" -eq 0 ]; then

    echo >&2 "Run with no args from cloud-init, exiting normally"
    exit
fi

echo >&2 "Starting up, args $0 $*"

git_ref=
kitchen_subdir="chef"
berks_subdir="berks-cookbooks"
berksfile_toplevel=
asg_name=
asg_lifecycle_hook_name=

while [ $# -gt 0 ] && [[ $1 = -* ]]; do
    case "$1" in
        --git-ref)
            git_ref="$2"
            shift
            ;;
        --kitchen-subdir)
            kitchen_subdir="$2"
            shift
            ;;
        --berksfile-toplevel)
            berksfile_toplevel=1
            ;;
        --asg-name)
            asg_name="$2"
            shift
            ;;
        --lifecycle-hook-name)
            asg_lifecycle_hook_name="$2"
            shift
            ;;
        --lifecycle-hook-abandon-delay)
            echo >&2 "Warning: --lifecycle-hook-abandon-delay is deprecated"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage
            echo >&2 "Unexpected option $1"
            exit 1
            ;;
    esac
    shift
done

if [ $# -ne 2 ]; then
    usage
    exit 1
fi

handle_error() {
    echo >&2 "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo >&2 "provision.sh: ERROR -- exiting after failure"
    echo >&2 "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"

    if [ -e "$INFO_DIR/skip_abandon_hook" ]; then
        echo >&2 "Flag file $INFO_DIR/skip_abandon_hook exists! Will not" \
            "send the ABANDON signal to the lifecycle hook."
        maybe_lifecycle_hook_heartbeat
        return
    fi

    echo >&2 "Sleeping 15 seconds before sending ABANDON signal..."
    sleep 15

    maybe_complete_lifecycle_hook ABANDON || /sbin/shutdown now
}

trap handle_error EXIT

s3_ssh_key_url="$1"
git_clone_url="$2"
secrets_dir=/etc/login.gov/keys
repos_dir=/etc/login.gov/repos

assert_root

# berks needs $HOME to be set for some reason, and we need to disable FIPS for it to run.
export HOME=/root
export CHEF_FIPS=''

# Read proxy variables from /etc/login.gov/info
proxy_server="$(cat "$INFO_DIR/proxy_server" || true)"
proxy_port="$(cat "$INFO_DIR/proxy_port" || true)"
no_proxy_hosts="$(cat "$INFO_DIR/no_proxy_hosts" || true)"

# Read SNS Topic for notifications
sns_topic_arn="$(cat "$INFO_DIR/sns_topic_arn" || true)"

#set proxy if provided
if [ -n "$proxy_server" ]; then
    configure_proxy
else
    echo >&2 "No proxy set in $INFO_DIR/proxy_server"
fi

set_newrelic_enpoints

echo "==========================================================="
echo "provision.sh: updating repo keys"
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - || true
apt-key adv --refresh-keys --keyserver-options http-proxy="http://$proxy_server:$proxy_port" --keyserver hkps://keyserver.ubuntu.com:443 || true

echo "==========================================================="
echo "provision.sh: downloading SSH key and cloning repo"

if [[ "$s3_ssh_key_url" != s3://* ]]; then
    echo >&2 "Warning: $s3_ssh_key_url does not start with s3://"
fi

run mkdir -vp "$secrets_dir"
run chmod -c 700 "$secrets_dir"

run aws s3 cp --sse aws:kms "$s3_ssh_key_url" "$secrets_dir/"
run aws s3 cp --sse aws:kms "$s3_ssh_key_url.pub" "$secrets_dir/"

ssh_key_path="$secrets_dir/$(basename "$s3_ssh_key_url")"
run chmod -c 600 "$ssh_key_path"

mkdir -vp "$repos_dir"

echo "cd $repos_dir"
cd "$repos_dir"

# GIT_SSH_COMMAND is only supported in git 2.3+
# We can switch to only using it once we are on Ubuntu >= 16.04
if [ "$(git --version)" = "git version 1.9.1" ]; then
    echo >&2 "Creating ssh-with-key as git SSH wrapper"
    git_ssh_wrapper="/usr/local/bin/ssh-with-key"
    cat > "$git_ssh_wrapper" <<'EOM'
#!/bin/sh
set -eux
exec ssh -i "$SSH_KEY_PATH" "$@"
EOM
    chmod -c +x "$git_ssh_wrapper"
    run env GIT_SSH="$git_ssh_wrapper" SSH_KEY_PATH="$ssh_key_path" \
        git clone "$git_clone_url"
else
    run env GIT_SSH_COMMAND="ssh -i '$ssh_key_path'" git clone "$git_clone_url"
fi

repo_basename="$(basename "$git_clone_url" .git)"

echo "cd $repo_basename"
cd "$repo_basename"

if [ -n "$git_ref" ]; then
    echo >&2 "Checking out specified git ref: $git_ref"
    run git checkout "$git_ref"
fi

#run "$embedded_bin/chef-client" --version

echo "==========================================================="
echo "provision.sh: running berks to vendor cookbooks"

# If Berksfile is at repo toplevel, run outside the kitchen_subdir
if [ -n "$berksfile_toplevel" ]; then
    echo >&2 "Running berks at toplevel"
    run berks vendor "$kitchen_subdir/$berks_subdir"
fi

echo "cd '$kitchen_subdir'"
cd "$kitchen_subdir"

# If Berksfile is not at repo toplevel, run inside the kitchen_subdir
if [ -z "$berksfile_toplevel" ]; then
    echo >&2 "Running berks"
    run berks vendor "$berks_subdir"
fi

echo "==========================================================="
echo "provision.sh: Starting chef run of $repo_basename!"

run pwd

# We expect there to be a chef-client.rb in the `chef` directory of the repo
# that tells us where to find cookbooks and also sets the environment and run
# list. (The run list probably needs to be set via a json_attribs file put in
# place by cloud-init or other provisioner).

# Chef doesn't error out if config not found, so we check ourselves
if ! [ -e "./chef-client.rb" ]; then
    echo >&2 "Error: no chef-client.rb found in $PWD"
    exit 3
fi

run "$embedded_bin/chef-client" --local-mode -c "./chef-client.rb" --no-color

run rm -rf /tmp/bundler

maybe_complete_lifecycle_hook CONTINUE || true

echo "==========================================================="
echo "All done! provision.sh finished for $repo_basename"
echo "==========================================================="
echo ''
trap - EXIT
