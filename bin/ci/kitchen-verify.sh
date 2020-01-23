#!/bin/bash
set -euo pipefail

subshell="$0"
run() {
    exec > >(sed "s~^~[$subshell]: ~")
    exec 2> >(sed "s~^~[$subshell]: ~" >&2)
    echo >&2 "+ $*"
    "$@"
}

usage() {
    cat >&2 <<EOM
usage: $(basename "$0")

Run kitchen verify against each node type in the CI environment, returning 0 on success.

Required environment variables:
\$KITCHEN_EC2_SSH_KEY: Path to the ssh key to use to log in
\$KITCHEN_EC2_SSH_KEYPAIR_ID: Name of the corresponding keypair in AWS

See https://github.com/18F/identity-devops/blob/master/doc/technical/testing/chef.md#test-kitchen-ec2-prerequisites for additional details
EOM
}

wait_for_subshells() {
    for pid in "${pids[@]}"; do
        wait "${pid}"
    done
}

kitchen_destroy() {
    echo "Destroying all node kitchen instances"

    # All previous subshells have terminated, reset to capture destroy shells
    pids=()

    # If a error is caught, still destroy the remaining instances
    set +e
    for node in `find nodes -type d -maxdepth 1 -not -path 'nodes/\.*' -not -name nodes -not -name common`; do
	(
	    cd ${node}
            subshell="${node}"
            run bundle exec kitchen destroy
	)&
	pids+=($!)
    done
    set -e
}

cleanup() {
    set +e
    for pid in "${pids[@]}"; do
        kill -9 $pid
    done
    wait_for_subshells
    kitchen_destroy
    wait_for_subshells
}

pids=()

if [ -z ${KITCHEN_EC2_SSH_KEY} ] || [ -z ${KITCHEN_EC2_SSH_KEYPAIR_ID} ]; then
    echo "KITCHEN_EC2_SSH_KEY and KITCHEN_EC2_SSH_KEYPAIR_ID must be set"
    usage
    exit 1
fi

if [ "${AWS_PROFILE}" != "identitysandbox.gov" ]; then
    echo "CI tests can only be run in the identitysandbox.gov CI environment"
    usage
    exit 1
fi

DIRNAME="$(dirname "${BASH_SOURCE[0]}")"

# If a error is caught, continue to destroy any kitchen VMs
trap "cleanup" EXIT

cd ${DIRNAME}/../..
for node in `find nodes -type d -maxdepth 1 -not -path 'nodes/\.*' -not -name nodes -not -name common`; do
        # Run kitchen verify in parallel across node types
	(
		cd ${node}
                subshell="${node}"
		run bundle exec kitchen verify
	)&
        pids+=($!)
done

wait_for_subshells

exit 0

