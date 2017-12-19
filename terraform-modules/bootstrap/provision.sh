#!/bin/bash

# Send all output to syslog and serial console unless we're being run by
# systemd, in which case assume that systemd is handling output logging.
# shellcheck disable=SC2009
if ! ps -o cgroup= $$ | grep ".service" >/dev/null ; then
    exec > >(tee >(logger -t provision.sh -s 2>/dev/console)) 2>&1
fi

set -euo pipefail

usage() {
    cat >&2 <<EOM
usage: $(basename "$0") [options] S3_SSH_KEY_URL GIT_CLONE_URL

This script helps provision an instance using chef. Steps it runs:

- Install chef, git, and other key dependencies
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
    --chef-download-url URL     URL to download the chef client debian package.
    --chef-download-sha256 SUM  The expected sha256 checksum of the chef file.
    --git-ref REF               Check out REF in id-do-private after cloning.
    --kitchen-subdir DIR        The subdirectory to cd to for running chef.

Needed config files:

    Inside the git repo, this script expects to find a chef repository in a
    subdirectory defined by --kitchen-subdir, or 'chef' by default.

    This directory must contain a 'chef-client.rb' file that contains
    everything needed to successfully run chef in local mode, including
    - environment
    - run list (typically via json_attribs file)
    - cookbook_path
    - chef_repo_path (will be the parent directory of the script)

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

install_awscli() {
    if ! which aws >/dev/null; then
        echo "Installing awscli"
        if ! which pip >/dev/null; then
            run apt-get install -y python-pip
        fi
        run pip install awscli
    fi
}

install_git() {
    if ! which git >/dev/null; then
        echo "Installing git"
        run apt-get install -y git
    fi
}

# usage: install_chef URL [CHECKSUM]
install_chef() {
    local tmpdir installer url expected_checksum checksum
    echo >&2 "Downloading chef"

    url="$1"
    expected_checksum="${2-}"

    tmpdir="$(run mktemp -d)"

    installer="$tmpdir/chef.deb"

    run wget -nv -O "$installer" "$url"

    if [ -n "$expected_checksum" ]; then
        checksum="$(run sha256sum "$installer" | cut -d' ' -f1)"
        if [ "$checksum" != "$expected_checksum" ]; then
            echo >&2 "Download checksum mismatch in $installer:"
            echo >&2 "Expected: $expected_checksum"
            echo >&2 "Got:      $checksum"
            return 2
        fi
    else
        echo >&2 "No checksum provided, not checking"
    fi

    echo >&2 "Installing chef"
    run dpkg -i "$installer"

    echo >&2 "Successfully installed"

    run rm -r "$tmpdir"
}

# Check whether berkshelf is already installed. If not, install berkshelf by
# using gem install to get a version appropriate for the chef embedded ruby
# version. This may be an old version of berkshelf.
check_install_berkshelf() {
    local embedded_bin ruby_version chef_version berks_version

    echo >&2 "Checking for installed berkshelf"

    if which berks >/dev/null; then
        echo >&2 "berks found on path"
        return
    fi

    embedded_bin="/opt/chef/embedded/bin"

    if [ ! -d "$embedded_bin" ]; then
        echo >&2 "Error: could not find chef embedded bin at $embedded_bin"
        return 1
    fi

    if [ -e "$embedded_bin/berks" ]; then
        echo >&2 "Berks found at $embedded_bin/berks"
        return
    fi

    echo >&2 "Installing berkshelf"

    run "$embedded_bin/chef-client" --version
    run "$embedded_bin/ruby" --version

    ruby_version="$(run "$embedded_bin/ruby" -e 'puts RUBY_VERSION')"

    chef_version="$(run "$embedded_bin/chef-client" --version)"

    case "$ruby_version" in
        2.1.*)
            run "$embedded_bin/gem" install -v '~> 1.2' nio4r
            run "$embedded_bin/gem" install -v '~> 4.3' berkshelf
            ;;
        2.2*|2.3*|2.4*)
            case "$chef_version" in
                'Chef: 12.'*)
                    run "$embedded_bin/gem" install -v '~> 5.0' berkshelf
                    ;;
                *)
                    echo "Unknown chef version $chef_version"
                    run "$embedded_bin/gem" install berkshelf
                    ;;
            esac
            ;;
        *)
            echo >&2 "Error: unknown ruby version $ruby_version"
            exit 3
    esac

    echo >&2 "Checking installed berkshelf"

    berks_version="$(run "$embedded_bin/berks" --version)"

    # belt + suspenders
    if [ -z "$berks_version" ]; then
        echo >&2 "Something went wrong"
        return 2
    fi

    # symlink into PATH as needed
    if ! which berks >/dev/null; then
        run ln -sfv "$embedded_bin/berks" "/usr/local/bin/berks"
    fi

    echo >&2 "Berkshelf version $berks_version is good to go!"
}

# If we appear to be a cloud-init user-data script running as root, exit zero.
if [[ $0 == /var/lib/cloud/instance/scripts/* ]] && \
    [ $# -eq 0 ] && [ "$(id -u)" -eq 0 ]; then

    echo >&2 "Run with no args from cloud-init, exiting normally"
    exit
fi

echo >&2 "Starting up, args $0 $*"

chef_download_url=
chef_download_sha256=
git_ref=
kitchen_subdir="chef"
berks_subdir="berks-cookbooks"
berksfile_toplevel=

while [ $# -gt 0 ] && [[ $1 = -* ]]; do
    case "$1" in
        --chef-download-url)
            chef_download_url="$2"
            shift
            ;;
        --chef-download-sha256)
            chef_download_sha256="$2"
            shift
            ;;
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

if [ $# -lt 2 ]; then
    usage
    exit 1
fi

print_error() {
    echo >&2 "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo >&2 "provision.sh: ERROR -- exiting after failure"
    echo >&2 "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
}

trap print_error EXIT

s3_ssh_key_url="$1"
git_clone_url="$2"
secrets_dir=/etc/login.gov/keys
repos_dir=/etc/login.gov/repos

assert_root

# berks needs $HOME to be set for some reason
export HOME=/root

echo "==========================================================="
echo "provision.sh: installing dependencies"

run apt-get update

DEBIAN_FRONTEND=noninteractive run apt-get \
    -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
    dist-upgrade -y

install_awscli
install_git

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

echo "==========================================================="
echo "provision.sh: installing chef and berkshelf"

if [ -n "$chef_download_url" ]; then
    install_chef "$chef_download_url" "$chef_download_sha256"
else
    echo >&2 "No --chef-download-url given, skipping chef install"
fi

run chef-client --version

check_install_berkshelf

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

run chef-client --local-mode -c "./chef-client.rb" --no-color

echo "==========================================================="
echo "All done! provision.sh finished for $repo_basename"
echo "==========================================================="
echo ''
trap - EXIT
