# Unhealthy Host Alert - ELB Edition

This module uses AWS-provided metrics and alerts when one or more previously
healthy instances registered to an ELB turns unhealthy.

This is only for ELBs as ALB/NLB place this metric under a per-TargetGroup
dimension.

This alarms are intended for critical external facing services.
