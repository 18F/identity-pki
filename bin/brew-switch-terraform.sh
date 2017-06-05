#!/usr/bin/env bash

set -eu

# Directory for homebrew formulae
HOMEBREW_CORE_DIR="${HOMEBREW_CORE_DIR-/usr/local/Homebrew/Library/Taps/homebrew/homebrew-core}"

# Directory for this script to install/manage terraform plugins
TERRAFORM_PLUGIN_DIR="${TERRAFORM_PLUGIN_DIR-"$HOME/.terraform-plugins"}"

# Location of terraform acme plugin symlink
ACME_SYMLINK="${TERRAFORM_PLUGIN_DIR}/terraform-provider-acme_current"

ACME_DOWNLOAD_URL="https://github.com/paybyphone/terraform-provider-acme/releases/download"

# Set this to skip ACME plugin management
SWITCH_TF_SKIP_ACME="${SWITCH_TF_SKIP_ACME-}"

# shellcheck source=/dev/null
. "$(dirname "$0")/lib/common.sh"

usage() {
    cat >&2 <<EOM
usage: $(basename "$0") TERRAFORM_VERSION

Use \`brew switch\` and \`brew install\` to install and switch to a given
version of terraform. It can also manage versions of the terraform ACME plugin,
which tends to be incompatible across releases.

For example:
    $(basename "$0") 0.9.6

This script has a built-in set of known homebrew versions that it can install
by checking out old versions of homebrew:
EOM
    get_homebrew_version_for_tf_version ALL | sed 's/^/    /'
}

# If macOS shipped with a modern version of bash (i.e. Bash 4.0), we would have
# associative arrays and wouldn't need this hack.
# Format: space separated columns.
# Column 1 - terraform version number
# Column 2 - homebrew git revision that can be used to install this version
# Column 3 - terraform-provider-acme plugin version for this TF version
KNOWN_TF_VERSIONS='
0.8.8 5745f2f232e3f6b3e3058b3e6ac6e3166822dc7c v0.2.1
0.9.6 92420144a10dc84a9847249be0845f06b2c3161b v0.3.0
'

# Look up row in KNOWN_TF_VERSIONS for given terraform version.
get_line_for_tf_version() {
    line="$(grep -w "^$1" <<< "$KNOWN_TF_VERSIONS")" && ret=$? || ret=$?

    if [ "$ret" -ne 0 ]; then
        cat >&2 <<EOM
Error: Sorry, I don't know how to build terraform version $1

You should add a new line for $1 to KNOWN_TF_VERSIONS in this script.
This script: $0

You'll need three columns to add the line:

1. The terraform version: $1

2. A homebrew version you can use to install.
   Look at git log of the homebrew formula:
     /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core/Formula/terraform.rb

3. The appropriate version of the terraform-provider-acme plugin to use.
   Visit the upstream site to see available versions:
     https://github.com/paybyphone/terraform-provider-acme/releases
EOM
        return 2
    fi

    echo "$line"
}

# Look up homebrew version that can be used to install given TF version.
get_homebrew_version_for_tf_version() {
    if [ "$1" = "ALL" ]; then
        echo "$KNOWN_TF_VERSIONS" | cut -d' ' -f1-2
        return
    fi

    line="$(get_line_for_tf_version "$1")"

    echo "$line" | cut -d' ' -f2
}

get_acme_version_for_tf_version() {
    line="$(get_line_for_tf_version "$1")"

    echo "$line" | cut -d' ' -f3
}

git_cleanup() {
    echo "ERROR: exiting without cleanup, will likely need to restore " \
        "original branch with \`git checkout -\`"
}

install_tf_version() {
    target="$1"

    git_rev="$(get_homebrew_version_for_tf_version "$target")"

    echo "install_tf_version installing terraform $target..."
    echo "Will check out homebrew-core to particular rev, install terraform"
    echo "homebrew-core revision: $git_rev"
    echo "homebrew-core dir: $HOMEBREW_CORE_DIR"

    # we need a full, non-shallow checkout of homebrew/core
    run brew tap --full homebrew/core

    run brew update

    echo >&2 "+ cd $HOMEBREW_CORE_DIR"
    cd "$HOMEBREW_CORE_DIR"

    run git fetch

    trap git_cleanup EXIT

    run git checkout "$git_rev"

    # if we already have any terraforms, unlink first
    if run brew list terraform; then
        run brew unlink terraform
    fi

    run env HOMEBREW_NO_AUTO_UPDATE=1 brew install terraform

    echo "Done install. Restoring homebrew to branch where it was before."

    run git checkout -

    trap - EXIT

    echo "New terraform was installed:"
    run terraform --version
}

setup_acme_plugin_management() {
    if [ ! -d "$TERRAFORM_PLUGIN_DIR" ]; then
        echo "TERRAFORM_PLUGIN_DIR does not exist: $TERRAFORM_PLUGIN_DIR"
        if prompt_yn "Should I create it for you?"; then
            run mkdir -v "$TERRAFORM_PLUGIN_DIR"
        else
            return 1
        fi
    fi

    if [ -e "$HOME/.terraformrc" ]; then
        if grep "$TERRAFORM_PLUGIN_DIR" "$HOME/.terraformrc" >/dev/null; then
            echo >&2 ".terraformrc appears to reference managed plugin dir"
        else
            cat >&2 <<EOM
Please modify ~/.terraformrc to include something like:
providers {
    acme = "$ACME_SYMLINK"
}
EOM
            if prompt_yn "Answer Yes when this is done"; then
                setup_acme_plugin_management
            else
                return 1
            fi
        fi
    else
        echo "$HOME/.terraformrc does not exist."
        if prompt_yn "Should I create it for you?"; then
            cat > "$HOME/.terraformrc" <<EOM
providers {
    acme = "$ACME_SYMLINK"
}
EOM
            echo "Created:"
            cat "$HOME/.terraformrc"
        else
            return 1
        fi
    fi
}

# usage: install_acme_version VERSION INSTALL_PATH
#
# Download ACME provider version VERSION from ACME_DOWNLOAD_URL and install it
# at INSTALL_PATH.
install_acme_version() {
    local tmpdir acme_version install_path arch download_basename
    acme_version="$1"
    install_path="$2"

    echo >&2 "Downloading Terraform ACME provider $acme_version"

    tmpdir="$(mktemp -d)"

    arch="darwin_amd64"

    download_basename="terraform-provider-acme_${acme_version}_${arch}.zip"

    run curl -SfL "$ACME_DOWNLOAD_URL/$acme_version/$download_basename" -o "$tmpdir/$download_basename"

    run unzip -d "$tmpdir" "$tmpdir/$download_basename"

    local expected_filename
    expected_filename="terraform-provider-acme"
    mv -v "$tmpdir/$expected_filename" "$install_path"

    echo >&2 "Installed terraform ACME provider $acme_version"

    rm -r "$tmpdir"
}

switch_acme_version() {
    local acme_version
    acme_version="$1"

    echo "Switching symlink to point to ACME provider version $acme_version"

    acme_target="$TERRAFORM_PLUGIN_DIR/terraform-provider-acme_${acme_version}_darwin_amd64"
    if [ ! -e "$acme_target" ]; then
        install_acme_version "$acme_version" "$acme_target"
    fi

    run ln -sfv "$acme_target" "$ACME_SYMLINK"

    echo "ACME provider symlink now points to version $acme_version"
}

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

target_version="$1"

if [[ $OSTYPE != *darwin* ]]; then
    echo "Unsupported OSTYPE: $OSTYPE"
    exit 2
fi

current_version="$(run terraform --version | head -1 | cut -d' ' -f2)"

if [ "v$target_version" = "$current_version" ]; then
    echo "Already running terraform $target_version"
    exit
fi

if ! run brew list --versions terraform | grep -q -w "$target_version"; then
    echo "Terraform $target_version does not appear to be installed."
    if prompt_yn "Install it?"; then
        install_tf_version "$target_version"
    fi
fi

run brew switch terraform "$target_version"

if [ -n "$SWITCH_TF_SKIP_ACME" ]; then
    echo "SWITCH_TF_SKIP_ACME is set, not managing ACME plugin"
else
    if setup_acme_plugin_management; then
        target_acme="$(get_acme_version_for_tf_version "$target_version")"

        switch_acme_version "$target_acme"
    else
        echo >&2 "Something went wrong in setting up ACME plugin management"
        echo >&2 "Set SWITCH_TF_SKIP_ACME=1 if you want to always skip this."
        exit 3
    fi
fi

echo 'All done!'
