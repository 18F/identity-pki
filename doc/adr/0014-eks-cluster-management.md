---

# Architecture Decision Record 14: EKS cluster management

> We will use kustomize for managing cluster resources

__Status__: Accepted

## Context

We need to figure out a good way to install resources into our clusters.  We will want to be installing multiple versions of applications into different namespaces with different naming prefixes and labels and so on used to distinguish them.  We will also need to install shared cluster resources such as prometheus and the kuma operator, etc.  These resources all need to be controlled via git and installed, in our case, with [ArgoCD](https://argo-cd.readthedocs.io/en/stable/).  We also need to make this system easy to understand, so that new team members can quickly get up to speed without having to learn a lot of layers and technologies.

There are many ways to do this.  Two of the ways that we have used successfully elsewhere are [Kustomize](https://kustomize.io/) and [Helm](https://helm.sh/).  There are advantages to both systems.

__Helm Strengths__:

* Helm is a familiar tool for many people.  It was sort of the first tool used to package things for other people to use to deploy kubernetes applications, so many people have done work with it.
* The templating language allows conditional cleverness.  You can hide a lot of logic behind a simple helm install.
* Helm’s templating capabilities may better support large applications with many configuration options, though it is not clear whether this is required for us.

__Kustomize Strengths__:

* Kustomize is a very simple tool.  It generally does not allow much cleverness, which means that it is hard to obfuscate what is going on.  For example, it doesn’t allow you to use conditional logic anywhere.  This means that there are less chances to be confused by logic or templating artifacts.  Our infrastructure has suffered from an abundance of "clever" homegrown stuff and confusing/hidden logic, so this should be considered a feature.
* The yaml which you are working with is real yaml, and thus is generally more readable and accessible to people working with the deployment.  The yaml is not hidden away inside a chart behind templating blocks.
* You can add cluster or env-specific yaml very easily in a single, consistent way.  For example, if you want to get jaeger going in dev, you can just slurp it down and add it in the dev kustomization.yaml file and not have to be clever with feature flags in the helm chart or leave potentially dangerous/confusing code where it could accidentally be activated in other environments.  If it is something that you do want to be globally available, you can plug it into the base layer.


Until now, we have been installing our clusters using [EKS blueprints](https://github.com/aws-ia/terraform-aws-eks-blueprints) and the [gitops-bridge](https://github.com/gitops-bridge-dev/terraform-helm-gitops-bridge), which installed EKS add-ons and ArgoCD.  ArgoCD was then set up to install a helm chart which installed a bunch of other helm charts to set up the cluster and the environments in them.

This meant that updating components like ArgoCD or the metrics-server sometimes meant we needed to go to terraform, and sometimes meant you needed to go to one of helm charts.  There was no centralized place that you could manage everything from.  It also meant that new features (and config!) needed to be plumbed into helm charts rather than just adding yaml to a directory.

Much more information and discussion about this decision can be found in the [Kustomize vs Helm](https://docs.google.com/document/d/1QNwbBV5jks6YwwpatxIHN9yiX5QgL7Zc4FqiUEJwAr0/edit#heading=h.3k2hdva3c5b9) document that we wrote to help us decide this.

## Decision

We will be using kustomize to manage our clusters and our deployments in them.

## Consequences

We will be refactoring our EKS clusters to not use the [gitops-bridge](https://github.com/gitops-bridge-dev/terraform-helm-gitops-bridge) tooling, and will reduce our use of EKS add-ons managed by terraform in favor of kustomize-managed deployments.  This will be done out of the https://gitlab.login.gov/lg-public/identity-eks-control repo, so that all code and config will be in one place.  This includes ArgoCD, which will be bootstrapped with a one-time helm install and then it will manage itself through a kustomize application.

We will be minimizing our use of helm to manage our login.gov application.  Vendored Helm charts will be used to install most 3rd party applications, but our app should be plain yaml that can be kustomized for naming and per-environment config.

If our app gets too big and complex, we may come to find that we will be wanting helm's flexible templating language.  We don't believe that we will run into that, but if we do, it shouldn't be too hard to throw the plain yaml into a helm chart and layer the required values and conditionals on with the templating language.  If we do that, then we will still retain the valuable property of managing all cluster resources in one place, though.  The helm chart would just be another application we would install using kustomize, rather than a helm of helm charts bootstrap thing as it is now.

Ultimately, we believe that the clean simplicity of Kustomize will keep us from being overly clever, and thus will keep our code simple, centralized, and easy to comprehend/manage, which is one of the most important goals that we hope to achieve with our containerization initiative.

## Alternatives Considered

We briefly looked at jsonnet but the fact that it’s a programming language makes it even _more_ complex for our use cases than even helm would be, which is the opposite direction we want to be moving in the first place.  It’s also pretty much json-focused, and not yaml-focused, so we’d have to do a lot of translation in our heads or with tools to make it readable.
