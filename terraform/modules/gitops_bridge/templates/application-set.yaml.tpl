apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: ${name}
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  syncPolicy:
    preserveResourcesOnDeletion: false
  generators:
    - local-cluster: {}
  template:
    metadata:
      name: '${name}'
    spec:
      project: default
      source:
        repoURL: '${repoURL}'
        path: '${path}'
        targetRevision: '${targetRevision}'
        helm:
          valueFiles:
%{ for vf in valueFiles ~}
            - ${vf}
%{ endfor ~}
          values: |
            ${indent(12, helmValues)}
      destination:
        namespace: argocd
        name: 'in-cluster'
      syncPolicy:
        automated: {}