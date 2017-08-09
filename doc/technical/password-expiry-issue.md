# Password Expiry Issue

We've had some issues with passwords expiring:

- https://github.com/18F/identity-devops-private/issues/288
- https://github.com/18F/identity-devops-private/issues/238
- https://github.com/18F/identity-devops-private/issues/348

This is fixed by https://github.com/18F/identity-devops-private/issues/327, but
in the meantime, before that is completely rolled out, here's the way to fix it:


```
for i in worker-0 worker-1 idp1-0 idp2-0 chef jenkins es0 es1 elk; do ssh $i.<env_name>.login.gov "sudo chage -M 99999 <username> && sudo chage -l <username>"; done
```

NOTE: The list of nodes may not match exactly what you have deployed in your
environment.  Use `knife node list` to find the current set of nodes.

It requires you to set your SSH config like this:
https://github.com/18F/identity-devops/blob/master/doc/technical/ssh.md#example-proxycommand-ssh-config
and set your username to the user you want to ssh as in that config.

If you have knife set up, you can use:

```
knife ssh "name:*" -x ubuntu "sudo /usr/bin/chage -E -1 <username> ; sudo /usr/bin/chage -m 0 -M 99999 -I -1 -E -1 -M -1 <username>"
```
