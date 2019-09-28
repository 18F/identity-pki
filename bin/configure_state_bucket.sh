#!/usr/bin/env bash

set -eu

# shellcheck source=/dev/null
. "$(dirname "$0")/lib/common.sh"

usage() {
  cat >&2 <<EOM
Usage: $0 [OPTIONS...] <bucket_name> <state_file_path> <terraform_dir> <region> <dynamodb_table>

Configure terraform to store state in S3 with a dynamodb lock table.

This script will create the relevant S3 bucket and dynamodb table as needed,
manage the .terraform directory with either the older symlinking style or the
newer separate subdirectory style, and then run \`terraform init\`.

Arguments:

    bucket_name:        Name of S3 bucket containing state files
    state_file_path:    S3 key path to the state file
    terraform_dir:      Directory in which to run terraform init
    region:             AWS region to connect to
    dynamodb_table:     Name of dynamodb table for state file locking

Options:
    -h, --help      Display this message
    --module-style   Use the newer separate subdirectory style and do not create
                    or manage any .terraform symlinks.
    --shared-style  Use the older shared style with .terraform symlinks.

This script understands two modes for managing the .terraform directory, where
terraform keeps local information about modules and remote state.

shared / identity-devops-private style:

    In the older, shared directory style, the terraform_dir is shared among
    multiple environments, with env variables delivered from
    identity-devops-private. This means that we have to blow away the
    .terraform directory every run so that there is no cross-env contamination.

    To make this safer, we use a system of symlinks so that the .terraform
    directory contents remain in persistently under .deploy/, and all we do on
    an individual run is to swap the .terraform symlink to point to it. This
    script manages a tree of .terraform directories under '.deploy/' scoped by
    the S3 state bucket, region, and key path.

module / local style: (newer, preferred)

    In the new style, where we keep a separate subdirectory for each
    environment, there is no reuse of the subdirectory, so we can use a
    standard plain .terraform directory without doing any special management.

EOM
}

# Log all terraform and aws commands in this script
terraform() {
  echo >&2 "+ terraform $*"
  env terraform "$@"
}
aws() {
  echo >&2 "+ aws $*"
  env aws "$@"
}

# Ensure remote state S3 bucket and dynamodb table exist.
# If not, create them.
check_or_create_remote_state_resources() {
  echo >&2 "+ aws s3api head-bucket --bucket $BUCKET"
  output="$(env aws s3api head-bucket --bucket "$BUCKET" 2>&1)" \
      && ret=$? || ret=$?

  if grep -F "Not Found" <<< "$output" >/dev/null; then
      log "$output"

      log "Bucket $BUCKET does not exist, creating..."
      log "Creating an s3 bucket for terraform state"

      aws s3 mb "s3://$BUCKET" --region "$REGION"

      log "Enabling versioning on the s3 bucket"
      aws s3api put-bucket-versioning --bucket "$BUCKET" \
          --versioning-configuration Status=Enabled

  elif [ "$ret" -ne 0 ]; then
      exit "$ret"
  fi

  log "State lock table: $LOCK_TABLE"

  if ! aws dynamodb describe-table --table-name "$LOCK_TABLE" \
          --region "$REGION" >/dev/null
  then
      log "Lock table does not exist, creating..."
      log "Creating a dynamodb table for terraform lock files"

      aws dynamodb create-table \
          --region "${REGION}" \
          --table-name "$LOCK_TABLE" \
          --attribute-definitions AttributeName=LockID,AttributeType=S \
          --key-schema AttributeName=LockID,KeyType=HASH \
          --sse-specification Enabled=true \
          --provisioned-throughput ReadCapacityUnits=2,WriteCapacityUnits=1

      log "Waiting for table to appear"

      aws dynamodb wait table-exists --table-name "$LOCK_TABLE" \
          --region "$REGION"

      log "Finished creating dynamodb table $LOCK_TABLE"
  fi
}

MODULE_STYLE=1
while [ $# -gt 0 ] && [[ $1 == -* ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --module-style)
      MODULE_STYLE=1
      ;;
    --shared-style)
      MODULE_STYLE=
      ;;
    *)
      usage
      echo_red >&2 "Unknown option: $1"
      exit 1
      ;;
  esac
  shift
done

if [ $# -ne 5 ] ; then
  usage
  exit 1
fi

BUCKET=$1
STATE=$2
TF_DIR=$3
REGION=$4
LOCK_TABLE=$5

if [ -n "$MODULE_STYLE" ]; then
  log --blue "Setting up TF state (local, module style .terraform)"
else
  log --blue "Setting up TF state and symlinking .terraform (shared style)"
fi

log "State file: $STATE"
log "State bucket: $BUCKET"


check_or_create_remote_state_resources


# Set up local .terraform directory with either the old or new .terraform
# directory management styles.
#
cd "${TF_DIR}"

# Sanity check: make sure we have a main.tf
assert_file_exists "main.tf"

if [ -z "$MODULE_STYLE" ]; then
  log --blue "Setting up shared style .terraform symlink"

  local_state_path=".deploy/$BUCKET/$REGION/$STATE/.terraform"

  if [ ! -d "$local_state_path" ]; then
      log "Creating new local state directory"
  fi

  mkdir -vp "$local_state_path" >&2

  if [ -L .terraform ]; then
      run rm -v .terraform >&2
  elif [ -d .terraform ]; then
      # We should no longer need to ever delete the .terraform directory.
      echo_red >&2 "error: .terraform is a directory, not the expected symlink"
      echo_red >&2 "Cowardly refusing to proceed"
      exit 5
  fi

  log "Linking .terraform to local state directory"

  run ln -sv "$local_state_path" .terraform >&2
fi

log --blue "Calling terraform init"

# https://github.com/hashicorp/terraform/issues/12762
case "$(CHECKPOINT_DISABLE=1 terraform --version)" in
  *v0.9.*|*v0.10.*|*v0.11.*)
    terraform init \
      -backend-config="bucket=${BUCKET}" \
      -backend-config="key=${STATE}" \
      -backend-config="dynamodb_table=$LOCK_TABLE" \
      -backend-config="region=${REGION}"
    ;;
  *)
    echo_red >&2 "$0: ERROR: Unsupported terraform version"
    exit 1
    ;;
esac
