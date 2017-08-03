#!/bin/bash
set -euo pipefail

# shellcheck source=/dev/null
. "$(dirname "$0")/lib/common.sh"

# delay before spinning down to original capacity, in minutes from now
default_spindown_mins=9

# Given an auto-scaling group, schedule a recycle of that group.
usage () {
    cat >&2 <<EOM
usage: $(basename "$0") ENVIRONMENT ROLE [NORMAL_CAPACITY]

Create AWS ASG scheduled actions to recycle instances in an ASG by spinning up
twice as many instances and then spinning back down to the usual number.

By default, spins up 2x instances immediately and spins down to the normal
number after $default_spindown_mins minutes from the current time.

If NORMAL_CAPACITY is set, then treat that as the resting desired capacity
rather than inferring the desired capacity from the current value in AWS.

For example:
    $(basename "$0") qa jumphost

EOM
}

# Calculate ISO timestamp for time DELAY seconds in the future. This would be
# easy to do with GNU date, but we want to work on OS X as well.
calculate_future_time() {
    local delay now future fmt
    delay="$1"
    now="$(date +%s)"
    future=$((now + delay))
    fmt="+%FT%TZ"

    case "$OSTYPE" in
        darwin*)
            # bsd date
            date -u -r "$future" "$fmt"
            ;;
        linux-gnu)
            # gnu date
            date -u --date "@$future" "$fmt"
            ;;
        *)
            echo >&2 "Unknown \$OSTYPE $OSTYPE"
            return 1
            ;;
    esac
}

# get_asg_info ASG_NAME
get_asg_info() {
    run aws autoscaling describe-auto-scaling-groups \
        --auto-scaling-group-names "$1" --output text \
        | grep "^AUTOSCALINGGROUPS"
}

# schedule_recycle ASG_NAME SPINDOWN_DELAY [DESIRED_CAPACITY]
schedule_recycle() {
    local asg_name="$1"
    local spindown_delay="$2"
    local desired_capacity="${3-}"
    local asg_info current_size max_size min_size new_size health_grace_period

    echo_blue "Scheduling ASG recycle of $asg_name"

    asg_info="$(get_asg_info "$asg_name")"

    current_size="$(cut -f 6 <<< "$asg_info")"
    max_size="$(cut -f 10 <<< "$asg_info")"
    min_size="$(cut -f 11 <<< "$asg_info")"
    health_grace_period="$(cut -f 7 <<< "$asg_info")"

    echo_blue "Current ASG capacity:"
    echo_blue "  desired: $current_size"
    echo_blue "  min:     $min_size"
    echo_blue "  max:     $max_size"
    echo_blue "Health check grace period: ${health_grace_period}s"

    if ((current_size == 0)); then
        echo_red "Error: current desired size is 0, nothing to recycle"
        return 1
    fi

    if (( health_grace_period > spindown_delay )); then
        echo_blue "  Grace period is > recycle delay, overriding as grace + 5m"
        spindown_delay=$((health_grace_period + 300))
    fi

    if [ -n "$desired_capacity" ]; then
        echo_yellow "Overriding $current_size with desired $desired_capacity"
        current_size="$desired_capacity"
    fi

    new_size="$((current_size * 2))"

    if ((new_size > max_size)); then
        echo_red "Error: cannot spin up $new_size instances, > max $max_size"
        return 1
    fi

    echo_blue "Will increase to $new_size instances immediately"
    echo_blue "Will return to   $current_size instances in ${spindown_delay}s"

    local spindown_time
    spindown_time="$(calculate_future_time "$spindown_delay")"

    run aws autoscaling set-desired-capacity \
        --auto-scaling-group-name "$asg_name" \
        --desired-capacity "$new_size"

    run aws autoscaling put-scheduled-update-group-action \
        --scheduled-action-name RecycleOnce_asg-recycle.sh \
        --auto-scaling-group-name "$asg_name" \
        --start-time "$spindown_time" \
        --desired-capacity "$current_size"

    echo_blue 'Done'
}

ASG_NAME=

if [ $# -lt 2 ]; then
    usage
    exit 1
fi

ENV="$1"
ROLE="$2"

if [ $# -ge 3 ]; then
    desired_capacity="$3"
else
    desired_capacity=
fi

ASG_NAME="$ENV-$ROLE"

schedule_recycle "$ASG_NAME" $((default_spindown_mins * 60)) \
    "$desired_capacity"
