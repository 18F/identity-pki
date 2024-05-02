apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${name}
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: '${repoURL}'
    path: '${path}'
    targetRevision: '${targetRevision}'
    helm:
      valueFiles:
%{ for vf in valueFiles ~}
        - '${vf}'
%{ endfor ~}
      values: |
        ${indent(8, helmValues)}
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true