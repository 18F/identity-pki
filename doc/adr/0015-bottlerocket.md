---

# Architecture Decision Record 15: EKS worker node AMI

> We will use Bottlerocket for the worker node AMI

__Status__: Accepted

## Definitions

EKS: Elastic Kubernetes Service

AMI: Amazon Machine Image

## Context

We have historically been using Amazon Linux 2 on our EKS worker nodes. In 2025,
Amazon Linux 2 will be EOL, meaning we need a replacement. The two main options
are Amazon Linux 2023 and Bottlerocket.

Amazon Linux 2023 is "more of the same" - a general purpose redhat based linux
distribution. Below we outline why Bottlerocket's security advantages make it a
better choice for worker nodes than sticking with a general purpose linux
distribution.

While Amazon Linux 2023 does come with various package updates and security
improvements, we believe Bottlerocket's smaller surface area and other security
settings make it a better choice for running containers with as little resource
and security overhead as possible.

### Bottlerocket

Bottlerocket is a purpose built OS for running containers, similar to Google's
Container-Optimized OS in Google Cloud. It has a read only root filesystem (there is a
writable filesystem for container-related operations like persistent volumes and
`/var/log/containers`) and does not even have a package manager.

Bottlerocket also runs SELinux in enforcing mode and is set up to make this very
difficult to turn off, further securing the host processes outside of containers.

https://aws.amazon.com/blogs/opensource/security-features-of-bottlerocket-an-open-source-linux-based-operating-system/

While remote access is available via SSM to a limited "control" container with
access to the host's API server, there is also an "admin" container that has
root access. For this reason we are not enabling SSM to the Bottlerocket hosts.
Because everything we do is in containers, we don't need root access to the host
so we won't enable it.

https://bottlerocket.dev/en/os/1.21.x/install/quickstart/aws/host-containers/

We continue to use Falco for logging syscalls via EBPF. Other security solutions
if needed can be installed via DaemonSet. Because there is no package manager,
there is no other way to install security solutions than as a DaemonSet.

Performance wise, Bottlerocket is fast to start up. From the time that an
unschedulable container is discovered, it takes 1-2 minutes for a node to start
up and be fully available including all daemonset pods and kuma service meshes.
If the pod coming up doesn't need a service mesh, this can be even faster,
between 30-60 seconds.

### Shared responsibility model

https://aws.github.io/aws-eks-best-practices/security/docs/#understanding-the-shared-responsibility-model

For EKS, Amazon has 3 options for worker nodes. In order of increasing customer
responsibility, they are Fargate, Managed Node Groups, and Self Managed Workers.

For Fargate, Amazon takes all the steps in securing the underlying
infrastructure. However, Fargate is not available to us due to not being
Fedramped.

For managed node groups, Amazon keeps the underlying AMI up to date and
configured, as long as we keep the node groups up to date. This means we want to
be sure to have auto updating to stay up to date in this regard.

For self managed nodes, everything related to worker nodes is under the
customer's responsibility with no assistance from Amazon.A

For these reasons, managed node groups make the most sense. As long as we keep
the AMI up to date and don't do any configuration of the user data, the launch
templates, or change the AMI, it's all configured by Amazon with the defaults.
This is often referred to internally as "breaking the seal".

## Decision

We will use Bottlerocket. Furthermore, we will use the Bottlerocket update
operator, or brupop, and install it on every cluster to automate updates.

## Consequences

### Updates

The Bottlerocket update operator, or brupop, automates updating nodes in place.
This means nodes will automatically update when new AMIs are available, without
requiring intervention to click a button in the AWS console.

However, we will still want to update the AMI version in the console
periodically because otherwise nodes will come up, be updated, and reboot,
adding extra churn onto the cluster that can be eliminated by updating the
initial image the worker nodes boot into.

Major updates with breaking changes, such as kernel versions, are tied to EKS
releases and new variants. These are tested in lower environments before being
rolled out to higher environments, just like EKS upgrades that happen 2-3 times
a year.

Minor updates during a given variant and EKS release
are limited to security updates.

https://github.com/bottlerocket-os/bottlerocket/blob/develop/SECURITY_FEATURES.md#update-policy

https://bottlerocket.dev/en/os/1.22.x/version-information/variants/

### Security features

* Automated updates (see above)
* Read only root filesystem
* No shells or package manager on the host system
* SELinux by default
* Kernel lockdown in integrity mode by default
* Secure boot

Source: https://github.com/bottlerocket-os/bottlerocket/blob/develop/SECURITY_FEATURES.md

### Read only root filesystem

Bottlerocket uses a read only root filesystem. Additionally, dm-verity to verify
the filesystem and if somehow it's changed despite being read only, will
automatically reboot. Additionally, when run on AWS, secure boot is enabled by
default so if the boot image is further tampered with, it will refuse to boot.

Source: https://github.com/bottlerocket-os/bottlerocket/blob/develop/SECURITY_FEATURES.md#immutable-rootfs-backed-by-dm-verity

### Security responsibilities

Short version: We're already doing these, most of which are either automatic,
enabled by default, or audited with kyverno and falco.

* Automatic updates: see above
* Avoid privileged containers: Audited with kyverno and falco
* Restrict access to host API socket: Audited with kyverno and falco
* Restrict access to the container runtime socket: Audited with kyverno and falco
* Design for host replacement: Already doing this
* Enable kernel lockdown: Enabled by default
* Limit use of host containers: We don't use these
* Limit use of privileged SELinux labels: Audited with kyverno and falco
* Limit access to system mounts: Audited with kyverno and falco
* Limit access to host namespaces: Audited with kyverno and falco
* Limit access to block devices: Audited with kyverno and falco
* Enforce requested NVIDIA GPU limits for unprivileged containers: We don't use GPUs
* Do not run containers as UID 0: Audited with kyverno and falco

Source: https://github.com/bottlerocket-os/bottlerocket/blob/develop/SECURITY_GUIDANCE.md

### Security benchmarks, host scanning

Out of the box, Bottlerocket passes CIS benchmarks for k8s level 2 and Bottlerocket level 1

(benchmarks run via SSM, temporarily enabled to get these reports)

For a more robust solution, we can either run a privileged pod manually, or run
a cronjob that runs these reports and exports them somewhere for recordkeeping
such as S3 or other compliance software.

If we need CIS level 2, we should first think carefully about how that would
improve our security posture when everything on these systems already runs
inside containers. If it's still necessary, this would "break the seal" (see
shared responsibility model above) and require us to build and configure our own
AMI.

Things to think about with CIS level 2 include the limitations already in place
if a container jailbreak exploit does exist in the wild. There is no shell
installed on the host OS so not much can be done in that regard. If an attacker
attempts to modify the root filesystem, dm-verity will automatically reboot the
system (see above, read-only root filesystem).

```
[ssm-user@control]$ apiclient report cis-k8s -l 2
Benchmark name:  CIS Kubernetes Benchmark (Worker Node)
Version:         v1.8.0
Reference:       https://www.cisecurity.org/benchmark/kubernetes
Benchmark level: 2
Start time:      2024-10-07T19:21:05.220443436Z

[PASS] 4.1.1     Ensure that the kubelet service file permissions are set to 644 or more restrictive (Automatic)
[PASS] 4.1.2     Ensure that the kubelet service file ownership is set to root:root (Automatic)
[SKIP] 4.1.3     If proxy kubeconfig file exists ensure permissions are set to 644 or more restrictive (Manual)
[SKIP] 4.1.4     If proxy kubeconfig file exists ensure ownership is set to root:root (Manual)
[PASS] 4.1.5     Ensure that the --kubeconfig kubelet.conf file permissions are set to 644 or more restrictive (Automatic)
[PASS] 4.1.6     Ensure that the --kubeconfig kubelet.conf file ownership is set to root:root (Automatic)
[PASS] 4.1.7     Ensure that the certificate authorities file permissions are set to 600 or more restrictive (Automatic)
[PASS] 4.1.8     Ensure that the client certificate authorities file ownership is set to root:root (Automatic)
[PASS] 4.1.9     If the kubelet config.yaml configuration file is being used validate permissions set to 600 or more restrictive (Automatic)
[PASS] 4.1.10    If the kubelet config.yaml configuration file is being used validate file ownership is set to root:root (Automatic)
[PASS] 4.2.1     Ensure that the --anonymous-auth argument is set to false (Automatic)
[PASS] 4.2.2     Ensure that the --authorization-mode argument is not set to AlwaysAllow (Automatic)
[PASS] 4.2.3     Ensure that the --client-ca-file argument is set as appropriate (Automatic)
[PASS] 4.2.4     Verify that the --read-only-port argument is set to 0 (Automatic)
[PASS] 4.2.5     Ensure that the --streaming-connection-idle-timeout argument is not set to 0 (Automatic)
[PASS] 4.2.6     Ensure that the --make-iptables-util-chains argument is set to true (Automatic)
[SKIP] 4.2.7     Ensure that the --hostname-override argument is not set (not valid for Bottlerocket) (Manual)
[SKIP] 4.2.8     Ensure that the eventRecordQPS argument is set to a level which ensures appropriate event capture (Manual)
[PASS] 4.2.9     Ensure that the --tls-cert-file and --tls-private-key-file arguments are set as appropriate (Automatic)
[SKIP] 4.2.10    Ensure that the --rotate-certificates argument is not set to false (not valid for Bottlerocket) (Manual)
[PASS] 4.2.11    Verify that the RotateKubeletServerCertificate argument is set to true (Automatic)
[PASS] 4.2.12    Ensure that the Kubelet only makes use of Strong Cryptographic Ciphers (Automatic)
[PASS] 4.2.13    Ensure that a limit is set on pod PIDs (Automatic)

Passed:          18
Failed:          0
Skipped:         5
Total checks:    23

Compliance check result: PASS
```

```
[ssm-user@control]$ apiclient report cis -l 1
Benchmark name:  CIS Bottlerocket Benchmark
Version:         v1.0.0
Reference:       https://www.cisecurity.org/benchmark/bottlerocket
Benchmark level: 1
Start time:      2024-10-07T19:22:31.187366260Z

[SKIP] 1.2.1     Ensure software update repositories are configured (Manual)
[PASS] 1.3.1     Ensure dm-verity is configured (Automatic)
[PASS] 1.4.1     Ensure setuid programs do not create core dumps (Automatic)
[PASS] 1.4.2     Ensure address space layout randomization (ASLR) is enabled (Automatic)
[PASS] 1.4.3     Ensure unprivileged eBPF is disabled (Automatic)
[PASS] 1.5.1     Ensure SELinux is configured (Automatic)
[SKIP] 1.6       Ensure updates, patches, and additional security software are installed (Manual)
[PASS] 2.1.1.1   Ensure chrony is configured (Automatic)
[PASS] 3.2.5     Ensure broadcast ICMP requests are ignored (Automatic)
[PASS] 3.2.6     Ensure bogus ICMP responses are ignored (Automatic)
[PASS] 3.2.7     Ensure TCP SYN Cookies is enabled (Automatic)
[SKIP] 3.4.1.3   Ensure IPv4 outbound and established connections are configured (Manual)
[SKIP] 3.4.2.3   Ensure IPv6 outbound and established connections are configured (Manual)
[PASS] 4.1.1.1   Ensure journald is configured to write logs to persistent disk (Automatic)
[PASS] 4.1.2     Ensure permissions on journal files are configured (Automatic)

Passed:          11
Failed:          0
Skipped:         4
Total checks:    15

Compliance check result: PASS
```

### Security agents

We hope that we can make better use of open source software such as Falco with
this solution. Ideally we can get Falco to produce the needed data and send it
to GSA SOC or whereever else this data is needed.

Agents that require host access do not work on Bottlerocket by design as
Bottlerocket lacks a package manager and everything must run in a container.

Some agents exist that can be run inside the cluster as a daemonset. One example
(not sure which GSA IT uses) is Prisma Cloud. However, many of these agents are
difficult to integrate with our gitops approach because they often require you
to generate a bespoke helm chart and install it with secrets. Additionally they
take up extra resources for daemonsets, requiring larger instances and more
spend.

We hope that we can integrate with existing SOC solutions using Falco and avoid
having to install agents, but it remains to be seen what will happen in this
regard yet.

### Shared concerns

Both options change the way IMDS works for improved security posture. The big
changes here are IMDSv2, and decreasing the hop limit to 1. This effectively
means pods no longer have access to IMDS. The reason this improves security is
that pods can no longer get access to the instance profile through IMDS,
bypassing their assigned role through pod identity.

Pods that still need IMDS access need to use host networking, which is audited
via Falco and Kyverno rules.

https://docs.aws.amazon.com/whitepapers/latest/security-practices-multi-tenant-saas-applications-eks/restrict-the-use-of-host-networking-and-block-access-to-instance-metadata-service.html

## Alternatives Considered

We looked at Amazon Linux 2023 as well, but decided to go with Bottlerocket instead.

## References

https://aws.github.io/aws-eks-best-practices/security/docs/#understanding-the-shared-responsibility-https

https://d1.awsstatic.com/whitepapers/compliance/Architecting_Amazon_EKS_and_Bottlerocket_for_PCI_DSS_Compliance.pdf

https://github.com/bottlerocket-os/bottlerocket/blob/develop/SECURITY_FEATURES.md

https://github.com/bottlerocket-os/bottlerocket/blob/develop/SECURITY_GUIDANCE.md

https://github.com/bottlerocket-os/bottlerocket/blob/develop/SECURITY_FEATURES.md#update-policy

https://bottlerocket.dev/en/os/1.22.x/version-information/variants/
