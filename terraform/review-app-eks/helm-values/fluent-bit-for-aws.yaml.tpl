enabled: true
additionalInputs: |
  [INPUT]
      Name                tail
      Tag                 kube.app.*
      Path                /var/log/containers/*identity*.log
      multiline.parser    docker\, cri
      DB                  /var/log/flb_container.db
      Mem_Buf_Limit       5MB
      Skip_Long_Lines     On
      Refresh_Interval    10
      Docker_Mode         On
  [INPUT]
      Name                tail
      Tag                 kube.infra.*
      Path                /var/log/containers/*.log
      Exclude_Path        /var/log/containers/*identity*.log
      multiline.parser    docker\, cri
      DB                  /var/log/flb_container.db
      Mem_Buf_Limit       5MB
      Skip_Long_Lines     On
      Refresh_Interval    10
      Docker_Mode         On
cloudWatchLogs:
  enabled: false
additionalOutputs: |
  [OUTPUT]
      Name              forward
      Match             kube.app.*
      Host              ${fluentd_host}
      Port              ${fluentd_port}
      Retry_Limit       False
  [OUTPUT]
      Name                  cloudwatch_logs
      Match                 kube.infra.*
      region                ${region}
      log_group_name        /aws/eks/fluentbit-cloudwatch/infra/logs
      log_stream_prefix     idp-
      log_group_template    /aws/eks/fluentbit-cloudwatch/infra/logs/$kubernetes['namespace_name']
      log_stream_template   $kubernetes['pod_name'].$kubernetes['labels']['app.kubernetes.io/name']
      log_key               log
      auto_create_group     true
enabled: true
filter:
  bufferSize: "32k"
  enabled: true
  k8sLoggingExclude: "Off"
  match: " kube.app.*"
  mergeLogKey: "log_processed"
  extraFilters: |
    Labels              On
    Annotations         On
    Kube_Tag_Prefix     kube.app.var.log.containers.
input:
  enabled: false
serviceAccount:
  annotations:
    "eks.amazonaws.com/role-arn": "${fluentbit_irsa_iam_role_arn}"
additionalFilters: |
  [FILTER]
      Name                kubernetes
      Match               kube.infra.*
      Kube_URL            https://kubernetes.default.svc.cluster.local:443
      Merge_Log           On
      Merge_Log_Key       log_processed
      Keep_Log            On
      K8S-Logging.Parser  On
      K8S-Logging.Exclude Off
      Buffer_Size         32k
      Labels              On
      Annotations         On
      Kube_Tag_Prefix     kube.infra.var.log.containers.