# Adding a new server type

(This doc is a stub, pull-requests welcome!)

There are several steps needed to create a new type of server. Suppose we're creating a new type of server, `foo` servers.

- Create an auto scaling group (ASG) and launch configuration in
  `terraform/app/foo-asg.tf`, probably using the bootstrap terraform module to
  manage the user-data used to bootstrap the instance.

  - The ASG should ideally be paired with an ALB/ELB so that the ASG can do
    health checks. This isn't always natural, but without it the ASG can only
    check whether the underlying hardware is healthy when doing health checks.

  - You'll probably need to create new variables to manage the ASG size. When
    introducing new services, we commonly create the ASG with a desired
    instance count of 0 so that the ASG is created without actually launching
    any instances.

- Create a new `foo` role in identity-devops to define the chef cookbooks and
  run list that should be run to provision each instance.
  `identity-devops:kitchen/roles/foo.json`

- Create a new `foo` role in identity-devops-private, which bootstraps users.
  This will likely be almost identical to an existing role in
  `identity-devops-private:chef/roles/`.
