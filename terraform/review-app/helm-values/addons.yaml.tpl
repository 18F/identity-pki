clusterName: ${clusterName}
repoUrl: ${repoUrl}
region: ${region}
targetRevision: ${targetRevision}
awsLoadBalancerController:
  createNamespace: true
  enable: true
  serviceAccount:
    create: true
    name: ${gitops_metadata["aws_load_balancer_controller_service_account"]}
    annotations:
      eks.amazonaws.com/role-arn: ${gitops_metadata["aws_load_balancer_controller_iam_role_arn"]}
certManager:
  enable: true
  serviceAccountName: ${gitops_metadata["cert_manager_service_account"]}
  serviceAccount:
    create: true
    annotations:
      eks.amazonaws.com/role-arn: ${gitops_metadata["cert_manager_iam_role_arn"]}
clusterAutoscaler:
  enable: true
  serviceAccountName: ${gitops_metadata["cluster_autoscaler_service_account"]}
  rbac:
    serviceAccount:
      create: true
      annotations:
        eks.amazonaws.com/role-arn: ${gitops_metadata["cluster_autoscaler_iam_role_arn"]}
externalDns:
  enable: true
  serviceAccountName: ${gitops_metadata["external_dns_service_account"]}
  serviceAccount:
    create: true
    annotations:
      eks.amazonaws.com/role-arn: ${gitops_metadata["external_dns_iam_role_arn"]}
  domainFilters:
%{ for domain in domainFilters ~}
    - "${domain}"
%{ endfor ~}
# Add additional values needed here