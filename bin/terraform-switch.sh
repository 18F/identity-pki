#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=/dev/null
. "$(dirname "$0")/lib/common.sh"

# Directory where we will install terraform
TERRAFORM_DOT_D="${TERRAFORM_DOT_D-}"
if [ -z "$TERRAFORM_DOT_D" ]; then
    TERRAFORM_DOT_D="$HOME/.terraform.d"
    if [ ! -d "$TERRAFORM_DOT_D" ]; then
        run mkdir -vp "$TERRAFORM_DOT_D"
    fi
fi

TF_DEPRECATED_DIR="${TF_DEPRECATED_DIR-"$HOME/.terraform-plugins"}"

TERRAFORM_EXE_DIR="$TERRAFORM_DOT_D/tf-switch"
TERRAFORM_PLUGIN_DIR="$TERRAFORM_DOT_D/plugin-cache"

TF_DOWNLOAD_URL="https://releases.hashicorp.com/terraform"

# Set this to skip installing TF symlink to TERRAFORM_SYMLINK
ID_TF_SKIP_SYMLINK="${ID_TF_SKIP_SYMLINK-}"

# Set this to skip GPG verification
ID_TF_SKIP_GPG="${ID_TF_SKIP_GPG-}"

# Set this to skip the terraform plugin cache check
ID_TF_SKIP_PLUGIN_CACHE="${ID_TF_SKIP_PLUGIN_CACHE-}"

# Location of installed TF symlink
TERRAFORM_SYMLINK="${TERRAFORM_SYMLINK-/usr/local/bin/terraform}"
SUDO_LN=

# Hashicorp GPG key fingerprint
TF_GPG_KEY_ID='72D7468F'
TF_OLD_GPG_FINGERPRINT=91A6E7F85D05C65630BEF18951852D87348FFC4C
TF_GPG_KEY_FINGERPRINT=C874011F0AB405110D02105534365D9472D7468F
TF_GPG_KEY_CONTENT='-----BEGIN PGP PUBLIC KEY BLOCK-----

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
ZF5q4h4I33PSGDdSvGXn9UMY5Isjpg==
=7pIB
-----END PGP PUBLIC KEY BLOCK-----
'

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
Keep multiple versions installed under $TERRAFORM_EXE_DIR and
symlink the chosen active binary at $TERRAFORM_SYMLINK.

Much of this script's behavior is configurable by environment variables, such
as TERRAFORM_SYMLINK to set the symlink install location, or TERRAFORM_DOT_D to
override the location used instead of ~/.terraform.d/.

For example:
    $(basename "$0") 0.13.7

Known Terraform versions:
EOM
    echo "${KNOWN_TF_VERSIONS[@]}" | tr ' ' '\n'
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
        "${download_prefix}/${checksum_file}"{,.${TF_GPG_KEY_ID}.sig} \
        "${download_prefix}/${download_basename}"

    if [ -n "$ID_TF_SKIP_GPG" ]; then
        echo "\$ID_TF_SKIP_GPG is set, skipping GPG verification"
    else
        echo >&2 "Checking GPG signature"

        if run gpg --batch --list-keys "$TF_OLD_GPG_FINGERPRINT"; then
            echo_yellow >&2 "Warning: found compromised GPG fingerprint $TF_OLD_GPG_FINGERPRINT in keychain."
            if prompt_yn "Remove this key automatically?"; then
                gpg --batch --delete-secret-and-public-key --yes "$TF_OLD_GPG_FINGERPRINT"
            else
                echo_red >&2 "Remove $TF_OLD_GPG_FINGERPRINT from GPG keychain, then re-run this script."
                return 1
            fi
        fi

        if ! run gpg --batch --list-keys "$TF_GPG_KEY_FINGERPRINT"; then
            #echo >&2 "Fetching Hashicorp GPG key"
            #run gpg --recv-keys "$TF_GPG_KEY_FINGERPRINT"
            echo >&2 "Importing Hashicorp GPG key"
            run gpg --import <<< "$TF_GPG_KEY_CONTENT"
        fi

        GPG_CHECK=$(run gpg --batch --status-fd 1 --verify "$checksum_file"{.${TF_GPG_KEY_ID}.sig,})
        
        if ! [[ $(echo "${GPG_CHECK}" | grep '^\[GNUPG:\] VALIDSIG '"$TF_GPG_KEY_FINGERPRINT") ]] ; then
            echo
            echo_red >&2 "$(basename "$0"): error, key not verified w/trusted signature"
            echo >&2 "Set ID_TF_SKIP_GPG=1 if you want to skip the signature check,"
            echo >&2 "or add trust with your own GPG key by running:"
            echo_cyan >&2 "gpg --lsign-key ${TF_GPG_KEY_FINGERPRINT}"
            echo
            return 1
        fi

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


setup_terraform_plugin_cache() {
    if [ -n "$ID_TF_SKIP_PLUGIN_CACHE" ]; then
        echo >&2 "Skipping terraform plugin cache management as requested"
        return
    fi

    if [ ! -d "$TERRAFORM_PLUGIN_DIR" ]; then
        run mkdir -v "$TERRAFORM_PLUGIN_DIR"
    fi

    if [ -e "$HOME/.terraformrc" ]; then
        if ! grep "^plugin_cache_dir " "$HOME/.terraformrc" >/dev/null; then
            cat >&2 <<EOM
Please modify ~/.terraformrc to include something like:

plugin_cache_dir = "\$HOME/.terraform.d/plugin-cache"

If you want to skip this check and not cache plugins, set
ID_TF_SKIP_PLUGIN_CACHE=1 when running this script.

EOM
            if prompt_yn "Answer Yes when this is done"; then
                setup_terraform_plugin_cache
            else
                return 1
            fi
        fi
    else
        echo "$HOME/.terraformrc does not exist."
        if prompt_yn "Should I create it for you?"; then
            cat > "$HOME/.terraformrc" <<EOM
plugin_cache_dir = "\$HOME/.terraform.d/plugin-cache"
EOM
            echo "Created:"
            cat "$HOME/.terraformrc"
        else
            return 1
        fi
    fi
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
        if run brew list terraform 2>/dev/null >/dev/null; then
            run brew unlink terraform
        fi
    fi

    echo_blue "Updating terraform symlink for $TERRAFORM_SYMLINK"

    if [ -n "$SUDO_LN" ]; then
        run sudo ln -sfv "$terraform_exe" "$TERRAFORM_SYMLINK"
    else
        run ln -sfv "$terraform_exe" "$TERRAFORM_SYMLINK"
    fi

}

deprecation_check() {
    if grep "$TF_DEPRECATED_DIR" "$HOME/.terraformrc" >/dev/null; then
        echo_yellow >&2 "Warning: found reference to $TF_DEPRECATED_DIR in $HOME/.terraformrc"
        echo_yellow >&2 "You may want to remove the acme plugin entirely from your ~/.terraformrc"
    fi

    if [ -d "$TF_DEPRECATED_DIR" ]; then
        echo_yellow >&2 "Warning: found directory from older terraform-switch.sh"
        echo_yellow >&2 "You may want to run: rm -r $TF_DEPRECATED_DIR"
    fi
}

main() {
    local target_version current_version terraform_exe

    target_version="$1"

    if which terraform >/dev/null; then
        current_version="$(get_terraform_version)"
    else
        current_version=
    fi

    setup_terraform_plugin_cache

    deprecation_check

    if [ "v$target_version" = "$current_version" ]; then
        echo "Already running terraform $target_version"
        return
    fi

    if ! which gpg >/dev/null; then
        echo_red >&2 "$(basename "$0"): error, gpg not found"
        echo >&2 "Set ID_TF_SKIP_GPG=1 if you want to skip the signature check"
        return 1
    fi

    if [ ! -e "$TERRAFORM_EXE_DIR" ]; then
        run mkdir -v "$TERRAFORM_EXE_DIR"
    fi

    terraform_exe="$TERRAFORM_EXE_DIR/terraform_${target_version}$EXE_SUFFIX"

    if [ -e "$terraform_exe" ]; then
        echo_blue "Terraform $target_version already installed at $terraform_exe"
    else
        echo "Terraform $target_version does not appear to be installed."
        if prompt_yn "Install it?"; then
            install_tf_version "$target_version" "$terraform_exe"
        fi
    fi

    install_tf_symlink "$terraform_exe"

    echo_blue 'All done!'
}

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

main "$@"
