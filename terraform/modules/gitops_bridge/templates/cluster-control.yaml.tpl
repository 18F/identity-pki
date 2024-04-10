apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${cluster_name}
  # You'll usually want to add your resources to the argocd namespace.
  namespace: argocd
  # Add a this finalizer ONLY if you want these to cascade delete.
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  # The project the application belongs to.
  project: default

  # Source of the application manifests
  source:
    repoURL: git@gitlab.login.gov:lg-public/identity-eks-control.git
    targetRevision: main
    path: cluster-${cluster_name}

    # kustomize specific config
    kustomize:
      # Optional kustomize version. Note: version must be configured in argocd-cm ConfigMap
      # version: v3.8.1
      # Optional image name prefix
      #namePrefix: system-
      # Optional images passed to "kustomize edit set image".
      #images:
      #- logindotgov/pretend-app


  # Destination cluster and namespace to deploy the application
  destination:
    server: https://kubernetes.default.svc
    namespace: default

  # Sync policy
  syncPolicy:
    automated:
      prune: true # Specifies if resources should be pruned during auto-syncing ( false by default ).
      selfHeal: true # Specifies if partial app sync should be executed when resources are changed only in target Kubernetes cluster and no git change detected ( false by default ).
    syncOptions:     # Sync options which modifies sync behavior
    - Validate=false # disables resource validation (equivalent to 'kubectl apply --validate=true')
