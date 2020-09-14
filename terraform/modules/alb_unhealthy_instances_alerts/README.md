# Unhealthy Host Alert - ALB/NLB Edition

This module uses AWS-provided metrics and alerts when one or more previously
healthy instances registered to an ALB or NLB turns unhealthy.

This is only for ALB/NLBs.  ELBs use a per-LB dimension for unhealthy host count.

This alarms are intended for critical external facing services.
