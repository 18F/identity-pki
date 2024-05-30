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
running versions, deployment progress, etc. To faciliate this, each cluster's
argocd instance (dev clusters as well as sandbox/staging/int/prod) will need an
ingress for access. This avoids needing a port forward and allows us to add more
granular permissions than just admin access.

## Decision

### Cluster access

We will handle cluster access via IAM. Different IAM roles such as devops, power
user, administrator, and oncall, will get access as necessary such as read only,
or further access appdev users in sandbox/staging, or for devops users and
oncall in production.

### ArgoCD

We will create ingresses for ArgoCD in each long lived cluster (sandbox/staging/etc).

We will set up ArgoCD authentication using gitlab, as gitlab access is already
setup via Login.gov, requires strong 2FA such as a hardware token (Yubikey) or
PIV card, and vetted via identity-devops and requires a background check before
gitlab access is granted.

We will further use gitlab group memberships for rbac authentication to ArgoCD
as appropriate for groups that need read only access vs further access.

For dev clusters, individual users can feel free to create gitlab apps in their
own user and provide the credentials, for convenience sake.

For any longer lived clusters, including sandbox, reviewapps, and clusters
inside the ATO boundary, we will create gitlab apps at either the group or
instance level (TBD). See the [gitlab
docs](https://docs.gitlab.com/ee/integration/oauth_provider.html) for more
information.

Reference information for creating the gitlab apps:

* Required scopes for the gitlab apps are `read_user` and `openid`
* Callback URL is https://argocd.clustername.identitysandbox.gov/api/dex/callback
* Client ID is an OIDC client id and not necessarily sensitive information.
* Client secret is sensitive information and needs to be stored in a k8s secret.


#### Inside ATO boundary

We require GFE to access ArgoCD inside the ATO boundary. This includes
production as well as other environments such as staging/int.

To ensure users are on GFE, and additionally limit our attack surface to systems
that may contain PII, we will limit access to ArgoCD instances inside the ATO
boundary to the GSA ip range. This is done by adding the following annotation to
the Ingress object:

```yaml
alb.ingress.kubernetes.io/inbound-cidrs: 159.142.0.0/16
```

The AWS load balancer controller uses this annotation to automatically configure
security group rules for the load balancer to limit access to the GSA IP ranges.

We will then work with GSA IT to route each domain name for long lived ArgoCD
instances through the GSA IP range using Zscaler (https://argocd.login.gov and
other hosts for staging/int clusters for example).

#### Lower environments

Lower environments include dev environments for the devops teams (johndoetest,
janedoetest, etc), as well as the sandbox cluster (long lived dev cluster for
shared testing), and reviewapps (cluster that automatically deploys PR branches
for testing of the IDP).

As some devs still don't have GFE, and lower environments do not contain PII,
for convenience in not having to engage GSA IT every time we create a new
cluster, we will allow ArgoCD instances in lower environments to be publicly
accessible over the internet. The instances are still protected via gitlab and
login.gov's strong 2FA requirement of yubikey or PIV card.

#### Permissions

##### Devops

Following the principle of least privilege, not even devops gets admin access to
the ArgoCD clusters inside the ATO boundary, as admin access to ArgoCD lets you
live edit manifests equivalently to having cluster admin on the kube clusters.

We can have a break glass setup to give devops admin access if needed, such as
using gitops to add the access in a break glass manner, or editing the configmap
via kubectl if argocd is down entirely.

Permissions for devops otherwise follow the oncall's permissions, with the
ability to use the break glass setting to give admin access if needed for
incident response.

Devops additionally gets access to all namespaces to do the following:

* Read only access
* Restart deployments (also available via kubectl)
* Promote progressive deployments/argo rollouts as necessary (though rollouts are typically only used in the idp namespace)

In lower environments, devops can have more permissions, up to and including
admin permissions on dev clusters to debug issues and develop new features/test
deploying new helm charts, as it's synonymous with kubectl admin access to
devops clusters anyway.

##### Oncall

Oncall permissions needed include the following:

* Read only access to all namespaces
* Restart deployments in idp namespace
* Promote progressive deployments/argo rollouts in idp namespace

##### Appdev

Appdev permissions include the following:

* Read only access to watch the progress of idp deployments

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
