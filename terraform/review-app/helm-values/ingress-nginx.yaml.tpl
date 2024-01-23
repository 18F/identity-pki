enabled: true
controller:
  config:
    use-proxy-protocol: "true"
  service:
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
      service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
      service.beta.kubernetes.io/aws-load-balancer-internal: "false"
      service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
  extraArgs:
    enable-ssl-passthrough: ""
  autoscaling:
    enabled: true
  admissionWebhooks:
    enabled: false
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: "${ingress_nginx_irsa_iam_role_arn}"