---

# Architecture Decision Record 13: Rails access in Kubernetes

> How to access the Rails console, rake tasks, etc in Kubernetes.

__Status__: Draft

## Context

Historically to access Rails console in production, we have long lived pet
instances that users can ssh into and run `rails console`, `rake my:task`, etc.
Because Kubernetes runs in containers inside pods, we need a different way to
get shell access.

In reviewapps we currently print out a message with access instructions:

```
# Source: login-chart/templates/pivcac/load-configmap-appyml-job.yaml
# Job to download and push ConfigMaps to the namespace prior to deployment
NOTES:
1. The application is running at the following URL:
  https://review-my-branch-abcd12.review-app.identitysandbox.gov/
DNS may take a while to propagate, so be patient if it doesn't show up right away
To access the rails console, first run 'aws-vault exec sandbox-power -- aws eks update-kubeconfig --name review_app'
Then run aws-vault exec sandbox-power -- kubectl exec -it service/review-my-branch-abcd12-login-chart-idp -n review-apps -- /app/bin/rails console
Address of IDP review app:
https://review-my-branch-abcd12.review-app.identitysandbox.gov
Address of PIVCAC review app:
https://review-my-branch-abcd12-review-app.pivcac.identitysandbox.gov
Address of Dashboard review app:
https://review-my-branch-abcd12-review-app-dashboard.review-app.identitysandbox.gov
```

### ArgoCD

Developers and oncalls may find it useful to have access to ArgoCD to check
running versions, deployment progress, etc. To faciliate this, each long lived
cluster's argocd instance (sandbox/staging) will need an ingress for access
without needing a port forward and to add more granular permissions than just
admin access.

## Decision

### Cluster access

We will handle cluster access via IAM. Different IAM roles such as devops, power
user, administrator, and oncall, will get access as necessary such as read only,
or further access appdev users in sandbox/staging, or for devops users and
oncall in production.

### ArgoCD

We will create ingresses for ArgoCD in each long lived cluster (sandbox/staging/etc).

We will set up ArgoCD authentication using gitlab, as gitlab access is already
setup via Login.gov and vetted via identity-devops.

We will further use gitlab group memberships for rbac authentication to ArgoCD
as appropriate for groups that need read only access vs further access.

### Instructions

We will publish the following instructions (exact names pending until we have
the apps running in a sandbox/staging environment to know for sure what it looks
like)

#### Update kubeconfig

```
aws-vault exec sandbox-power -- aws eks update-kubeconfig --name staging
```

#### Advanced

(to let you seamlessly switch between contexts in k9s or not need to prefix your
commands with aws-vault exec)

Edit cluster entries in your kubeconfig to look like this:

```diff
  user:
    exec:
      args:
+     - exec
+     - sandbox-admin
+     - --
+     - aws
      - --region
      - us-west-2
      - eks
      - get-token
      - --cluster-name
      - sandbox
      - --output
      - json
-     command: aws
+     command: aws-vault
```

If you ever run `aws eks update-kubeconfig` for a given cluster you need to
manually edit that entry in your kubeconfig again

#### Rails console

```
kubectl config use staging
aws-vault exec sandbox-power -- kubectl exec -it service/idp -n idp -- /app/bin/rails console
```

#### Rake tasks

```
kubectl config use staging
aws-vault exec sandbox-power -- kubectl exec -it service/idp -n idp -- /app/bin/rake my:task
```

#### Logs

Pod logs available via kubectl, should also be in cloudwatch (TODO where?)

## Consequences

### Draft status

The current state of this ADR has placeholder instructions until we have
long-lived sandbox/staging clusters setup for appdev to use. When we get to that
point we need to update the instructions with actual cluster names, namespaces,
etc.

### Production

The instructions will need to be updated with the AWS account, cluster name,
namespace, and service name for the production apps.

## Alternatives Considered

### Kubernetes dashboard

This is an extra app to maintain, and information is already available via
ArgoCD which we already operate.

### Rancher

This is an extra app to maintain when we already publish instructions for
aws-vault and kubectl for reviewapps. Additionally, other desktop apps are
available for visualizing k8s resources that can utilize the same kubeconfig
such as [k9s](https://github.com/derailed/k9s).

### GSA SSO for ArgoCD instead of Gitlab authentication

This would put a dependency on GSA IT for ingress and routing. Gitlab users are
already provisioned manually with approval, and the only login option is with
Login.gov which has 2FA. We already have more granular groups in place via AWS
and Gitlab auth than the time it would take to learn and integrate with GSA SSO.
