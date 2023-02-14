#!/bin/bash

for name in $(aws cloudwatch describe-alarms|jq -r '.MetricAlarms[].AlarmName'|grep -v -- " "); do
    echo "$name" "." "1"
done \
| xargs dialog --stdout --checklist "Select Alarms" 40 80 20 \
| xargs -n 1 -J % aws cloudwatch set-alarm-state --alarm-name % --state-value ALARM --state-reason "*** Manual test ***"
