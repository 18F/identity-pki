#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=/dev/null
. "$(dirname "$0")/lib/common.sh"

# Directory where we will install terraform
TERRAFORM_PLUGIN_DIR="${TERRAFORM_PLUGIN_DIR-}"
if [ -z "$TERRAFORM_PLUGIN_DIR" ]; then
    TERRAFORM_PLUGIN_DIR="$HOME/.terraform-plugins"
    if [ ! -d "$TERRAFORM_PLUGIN_DIR" ]; then
        run mkdir -vp "$TERRAFORM_PLUGIN_DIR"
    fi
fi

ACME_DOWNLOAD_URL="https://github.com/paybyphone/terraform-provider-acme/releases/download"
TF_DOWNLOAD_URL="https://releases.hashicorp.com/terraform"

# Set this to skip ACME plugin management
# Skipping is now enabled by default since we no longer use the ACME plugin.
ID_TF_INSTALL_ACME="${ID_TF_INSTALL_ACME-}"

# Set this to skip installing TF symlink to TERRAFORM_SYMLINK
ID_TF_SKIP_SYMLINK="${ID_TF_SKIP_SYMLINK-}"

# Set this to skip GPG verification
ID_TF_SKIP_GPG=

# Location of terraform acme plugin symlink
ACME_SYMLINK="${TERRAFORM_PLUGIN_DIR}/terraform-provider-acme_current"

# Location of installed TF symlink
TERRAFORM_SYMLINK="${TERRAFORM_SYMLINK-/usr/local/bin/terraform}"
SUDO_LN=

# Hashicorp GPG key fingerprint
TF_GPG_KEY_FINGERPRINT=91A6E7F85D05C65630BEF18951852D87348FFC4C

# Disable terraform auto update nonsense
export CHECKPOINT_DISABLE=1

EXE_SUFFIX=
case "$OSTYPE" in
    *darwin*)  TF_OS=darwin ;;
    linux-gnu) TF_OS=linux ;;
    cygwin|msys)
        TF_OS=windows
        EXE_SUFFIX=.exe
        ;;
    solaris*) TF_OS=solaris ;;
    freebsd*) TF_OS=freebsd ;;
    *)
        echo >&2 "Unknown OSTYPE '$OSTYPE'"
        echo >&2 "If you know the appropriate mapping, add this to the OSTYPE"
        echo >&2 "case statement: using $TF_DOWNLOAD_URL"
        exit 3
        ;;
esac

case "$(uname -m)" in
    x86_64|amd64) TF_ARCH=amd64 ;;
    i386|i686) TF_ARCH=386 ;;
    arm*) TF_ARCH=arm ;;
    *)
        echo >&2 "Unknown architecture '$(uname -m)'"
        exit 4
        ;;
esac

usage() {
    cat >&2 <<EOM
usage: $(basename "$0") TERRAFORM_VERSION

Download and install precompiled terraform binaries from Github.
Keep multiple versions installed under $TERRAFORM_PLUGIN_DIR and
symlink the chosen active binary at $TERRAFORM_SYMLINK.

Also manage the versions of the terraform ACME plugin, which tends to be
incompatible across releases.

Much of this script's behavior is configurable by environment variables, such
as TERRAFORM_SYMLINK to set the symlink install location, or ID_TF_INSTALL_ACME
to enable installation of the ACME plugin (currently unused).

For example:
    $(basename "$0") 0.9.11

Known Terraform versions:
EOM
    echo "$KNOWN_TF_VERSIONS" | cut -d' ' -f1 | sed 's/^/    /'
}

# If macOS shipped with a modern version of bash (i.e. Bash 4.0), we would have
# associative arrays and wouldn't need this hack.
# Format: space separated columns.
# Column 1 - terraform version number
# Column 2 - terraform-provider-acme plugin version for this TF version
#
# Upstream references for the releases:
#   - https://releases.hashicorp.com/terraform/
#   - https://github.com/paybyphone/terraform-provider-acme/releases
#
KNOWN_TF_VERSIONS='
0.8.8 v0.2.1
0.9.6 v0.3.0
0.9.11 v0.3.0
0.10.8 v0.5.0
0.11.7 v0.5.0
'

# Look up row in KNOWN_TF_VERSIONS for given terraform version.
get_line_for_tf_version() {
    line="$(grep -w "^$1" <<< "$KNOWN_TF_VERSIONS")" && ret=$? || ret=$?

    if [ "$ret" -ne 0 ]; then
        echo_red >&2 "Error: Sorry, I don't have info on terraform version $1"
        cat >&2 <<EOM

You should add a new line for $1 to KNOWN_TF_VERSIONS in this script.
This script: $0

You'll need two columns to add the line:

1. The terraform version: $1

2. The appropriate version of the terraform-provider-acme plugin to use.
   Visit the upstream site to see available versions:
     https://github.com/paybyphone/terraform-provider-acme/releases
EOM
        return 2
    fi

    echo "$line"
}

get_acme_version_for_tf_version() {
    line="$(get_line_for_tf_version "$1")"

    echo "$line" | cut -d' ' -f2
}

sha256_cmd() {
    if which sha256sum >/dev/null; then
        run sha256sum "$@"
    elif which shasum >/dev/null; then
        run shasum -a 256 "$@"
    else
        echo >&2 "Could not find sha256sum or shasum"
        return 1
    fi
}

install_tf_version() {
    local target download_prefix terraform_exe tmpdir checksum_file csum
    local download_basename
    target="$1"
    terraform_exe="$2"

    echo_blue "Installing terraform version $target"

    download_prefix="$TF_DOWNLOAD_URL/$target"
    download_basename="terraform_${target}_${TF_OS}_${TF_ARCH}.zip"
    checksum_file="terraform_${target}_SHA256SUMS"

    tmpdir="$(mktemp -d)"

    (
    echo >&2 "+ cd '$tmpdir'"
    cd "$tmpdir"

    run curl -Sf --remote-name-all \
        "${download_prefix}/${checksum_file}"{,.sig} \
        "${download_prefix}/${download_basename}"

    if [ -n "$ID_TF_SKIP_GPG" ]; then
        echo "\$ID_TF_SKIP_GPG is set, skipping GPG verification"
    else
        echo >&2 "Checking GPG signature"

        if ! run gpg --batch --list-keys "$TF_GPG_KEY_FINGERPRINT"; then
            echo >&2 "Fetching Hashicorp GPG key"
            run gpg --recv-keys "$TF_GPG_KEY_FINGERPRINT"
        fi

        run gpg --batch --status-fd 1 --verify "$checksum_file"{.sig,} \
            | grep '^\[GNUPG:\] VALIDSIG '"$TF_GPG_KEY_FINGERPRINT"

        echo >&2 "OK, finished verifying"
    fi

    echo >&2 "Checking SHA256 checksum"
    csum="$(run grep "${TF_OS}_${TF_ARCH}.zip" "$checksum_file")"
    sha256_cmd -c <<< "$csum"

    echo >&2 "OK"

    run unzip -d "$tmpdir" "$tmpdir/$download_basename"

    mv -v "$tmpdir/terraform" "$terraform_exe"
    )

    rm -r "$tmpdir"

    echo_blue "New terraform was installed to $terraform_exe"
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

    arch="${TF_OS}_${TF_ARCH}"

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

    if [ -z "$acme_version" ]; then
        return 1
    fi

    echo "Switching symlink to point to ACME provider version $acme_version"

    acme_target="$TERRAFORM_PLUGIN_DIR/terraform-provider-acme_${acme_version}_${TF_OS}_amd64"
    if [ ! -e "$acme_target" ]; then
        install_acme_version "$acme_version" "$acme_target"
    fi

    run ln -sfv "$acme_target" "$ACME_SYMLINK"

    echo "ACME provider symlink now points to version $acme_version"
}

install_tf_symlink() {
    local terraform_exe
    terraform_exe="$1"

    if [ -n "$ID_TF_SKIP_SYMLINK" ]; then
        echo "ID_TF_SKIP_SYMLINK is set, not installing terraform symlink"
        return
    fi

    # if homebrew terraform is installed, unlink it
    if which brew >/dev/null; then
        # if we already have any terraforms, unlink first
        if run brew list terraform; then
            run brew unlink terraform
        fi
    fi

    echo_blue "Installing terraform symlink to $TERRAFORM_SYMLINK"

    if [ -n "$SUDO_LN" ]; then
        run sudo ln -sfv "$terraform_exe" "$TERRAFORM_SYMLINK"
    else
        run ln -sfv "$terraform_exe" "$TERRAFORM_SYMLINK"
    fi
}

main() {
    local target_version current_version terraform_exe target_acme

    target_version="$1"

    if which terraform >/dev/null; then
        current_version="$(run terraform --version | head -1 | cut -d' ' -f2)"
    else
        current_version=
    fi

    if [ "v$target_version" = "$current_version" ]; then
        echo "Already running terraform $target_version"
        return
    fi

    if ! which gpg >/dev/null; then
        echo >&2 "$(basename "$0"): error, gpg not found"
        echo >&2 "Set ID_TF_SKIP_GPG=1 if you want to skip the signature check"
        return 1
    fi

    terraform_exe="$TERRAFORM_PLUGIN_DIR/terraform_${target_version}$EXE_SUFFIX"

    if [ -e "$terraform_exe" ]; then
        echo_blue "Terraform $target_version already installed at $terraform_exe"
    else
        echo "Terraform $target_version does not appear to be installed."
        if prompt_yn "Install it?"; then
            install_tf_version "$target_version" "$terraform_exe"
        fi
    fi

    install_tf_symlink "$terraform_exe"

    if [ -z "$ID_TF_INSTALL_ACME" ]; then
        echo "ID_TF_INSTALL_ACME is not set, not managing ACME plugin"
    else
        echo_blue "Setting up terraform ACME plugin"
        if setup_acme_plugin_management; then
            target_acme="$(get_acme_version_for_tf_version "$target_version")"

            switch_acme_version "$target_acme"
        else
            echo >&2 "Something went wrong in setting up ACME plugin management"
            exit 3
        fi
    fi

    echo_blue 'All done!'
}

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

main "$@"
