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
TF_GPG_KEY_FINGERPRINT=91A6E7F85D05C65630BEF18951852D87348FFC4C
TF_GPG_KEY_CONTENT='
-----BEGIN PGP PUBLIC KEY BLOCK-----

mQENBFMORM0BCADBRyKO1MhCirazOSVwcfTr1xUxjPvfxD3hjUwHtjsOy/bT6p9f
W2mRPfwnq2JB5As+paL3UGDsSRDnK9KAxQb0NNF4+eVhr/EJ18s3wwXXDMjpIifq
fIm2WyH3G+aRLTLPIpscUNKDyxFOUbsmgXAmJ46Re1fn8uKxKRHbfa39aeuEYWFA
3drdL1WoUngvED7f+RnKBK2G6ZEpO+LDovQk19xGjiMTtPJrjMjZJ3QXqPvx5wca
KSZLr4lMTuoTI/ZXyZy5bD4tShiZz6KcyX27cD70q2iRcEZ0poLKHyEIDAi3TM5k
SwbbWBFd5RNPOR0qzrb/0p9ksKK48IIfH2FvABEBAAG0K0hhc2hpQ29ycCBTZWN1
cml0eSA8c2VjdXJpdHlAaGFzaGljb3JwLmNvbT6JATgEEwECACIFAlMORM0CGwMG
CwkIBwMCBhUIAgkKCwQWAgMBAh4BAheAAAoJEFGFLYc0j/xMyWIIAIPhcVqiQ59n
Jc07gjUX0SWBJAxEG1lKxfzS4Xp+57h2xxTpdotGQ1fZwsihaIqow337YHQI3q0i
SqV534Ms+j/tU7X8sq11xFJIeEVG8PASRCwmryUwghFKPlHETQ8jJ+Y8+1asRydi
psP3B/5Mjhqv/uOK+Vy3zAyIpyDOMtIpOVfjSpCplVRdtSTFWBu9Em7j5I2HMn1w
sJZnJgXKpybpibGiiTtmnFLOwibmprSu04rsnP4ncdC2XRD4wIjoyA+4PKgX3sCO
klEzKryWYBmLkJOMDdo52LttP3279s7XrkLEE7ia0fXa2c12EQ0f0DQ1tGUvyVEW
WmJVccm5bq25AQ0EUw5EzQEIANaPUY04/g7AmYkOMjaCZ6iTp9hB5Rsj/4ee/ln9
wArzRO9+3eejLWh53FoN1rO+su7tiXJA5YAzVy6tuolrqjM8DBztPxdLBbEi4V+j
2tK0dATdBQBHEh3OJApO2UBtcjaZBT31zrG9K55D+CrcgIVEHAKY8Cb4kLBkb5wM
skn+DrASKU0BNIV1qRsxfiUdQHZfSqtp004nrql1lbFMLFEuiY8FZrkkQ9qduixo
mTT6f34/oiY+Jam3zCK7RDN/OjuWheIPGj/Qbx9JuNiwgX6yRj7OE1tjUx6d8g9y
0H1fmLJbb3WZZbuuGFnK6qrE3bGeY8+AWaJAZ37wpWh1p0cAEQEAAYkBHwQYAQIA
CQUCUw5EzQIbDAAKCRBRhS2HNI/8TJntCAClU7TOO/X053eKF1jqNW4A1qpxctVc
z8eTcY8Om5O4f6a/rfxfNFKn9Qyja/OG1xWNobETy7MiMXYjaa8uUx5iFy6kMVaP
0BXJ59NLZjMARGw6lVTYDTIvzqqqwLxgliSDfSnqUhubGwvykANPO+93BBx89MRG
unNoYGXtPlhNFrAsB1VR8+EyKLv2HQtGCPSFBhrjuzH3gxGibNDDdFQLxxuJWepJ
EK1UbTS4ms0NgZ2Uknqn1WRU1Ki7rE4sTy68iZtWpKQXZEJa0IGnuI2sSINGcXCJ
oEIgXTMyCILo34Fa/C6VCm2WBgz9zZO8/rHIiQm1J5zqz0DrDwKBUM9C
=LYpS
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
    $(basename "$0") 0.9.11

Known Terraform versions:
EOM
    echo "$KNOWN_TF_VERSIONS" | cut -d' ' -f1 | sed 's/^/    /'
}

# If macOS shipped with a modern version of bash (i.e. Bash 4.0), we would have
# associative arrays and wouldn't need this hack.
#
# Upstream references for the releases:
#   - https://releases.hashicorp.com/terraform/
#
KNOWN_TF_VERSIONS='
0.9.11
0.10.8
0.11.14
0.12.17
'

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
            #echo >&2 "Fetching Hashicorp GPG key"
            #run gpg --recv-keys "$TF_GPG_KEY_FINGERPRINT"
            echo >&2 "Importing Hashicorp GPG key"
            run gpg --import <<< "$TF_GPG_KEY_CONTENT"
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
        echo >&2 "$(basename "$0"): error, gpg not found"
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
